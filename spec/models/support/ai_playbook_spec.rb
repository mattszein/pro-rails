require "rails_helper"

RSpec.describe Support::AiPlaybook, type: :model do
  it "has a valid factory" do
    expect(build(:ai_playbook)).to be_valid
  end

  it "defaults to assist mode with sane limits" do
    playbook = described_class.new
    expect(playbook).to be_assist
    expect(playbook.max_ai_turns).to eq(4)
    expect(playbook.idle_reminder_after_hours).to eq(24)
    expect(playbook.idle_handoff_after_hours).to eq(48)
    expect(playbook.categories).to eq([])
  end

  describe "validations" do
    subject { build(:ai_playbook) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    it "bounds priorities to 1..5" do
      expect(build(:ai_playbook, min_priority: 0)).not_to be_valid
      expect(build(:ai_playbook, max_priority: 6)).not_to be_valid
      expect(build(:ai_playbook, min_priority: 1, max_priority: 5)).to be_valid
    end

    it "requires min_priority <= max_priority" do
      expect(build(:ai_playbook, min_priority: 4, max_priority: 2)).not_to be_valid
      expect(build(:ai_playbook, min_priority: 3, max_priority: 3)).to be_valid
    end

    it "requires positive max_ai_turns and idle hours" do
      expect(build(:ai_playbook, max_ai_turns: 0)).not_to be_valid
      expect(build(:ai_playbook, idle_reminder_after_hours: 0)).not_to be_valid
    end

    it "requires handoff hours >= reminder hours" do
      expect(build(:ai_playbook, idle_reminder_after_hours: 10, idle_handoff_after_hours: 5)).not_to be_valid
      expect(build(:ai_playbook, idle_reminder_after_hours: 10, idle_handoff_after_hours: 10)).to be_valid
    end

    it "only accepts known category values" do
      expect(build(:ai_playbook, categories: [0, 2])).to be_valid
      expect(build(:ai_playbook, categories: [99])).not_to be_valid
    end
  end

  describe "#category_keys" do
    it "maps stored integers to keys and back" do
      playbook = build(:ai_playbook, categories: [2, 0])
      expect(playbook.category_keys).to eq(%w[billing account_access])
      playbook.category_keys = ["", "technical_issue"]
      expect(playbook.categories).to eq([1])
    end
  end

  describe "default playbook" do
    it "allows only one default" do
      create(:ai_playbook, :default)
      other = build(:ai_playbook, :default)
      expect(other).not_to be_valid
    end

    it "enforces a single default at the database level" do
      create(:ai_playbook, :default)
      other = build(:ai_playbook, :default)
      expect { other.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "cannot be destroyed" do
      playbook = create(:ai_playbook, :default)
      expect(playbook.destroy).to be(false)
      expect(playbook.errors[:base]).to be_present
      expect(described_class.exists?(playbook.id)).to be(true)
    end

    it "lets non-default playbooks be destroyed" do
      playbook = create(:ai_playbook)
      expect(playbook.destroy).to be_truthy
    end

    it ".default_playbook returns it" do
      default = create(:ai_playbook, :default)
      create(:ai_playbook)
      expect(described_class.default_playbook).to eq(default)
    end
  end

  describe "capabilities" do
    it "accepts every registered key" do
      keys = SupportAi::Capabilities::Registry.keys.map(&:to_s)
      expect(build(:ai_playbook, capabilities: keys)).to be_valid
    end

    it "rejects an unregistered key on :capabilities" do
      playbook = build(:ai_playbook, capabilities: %w[account_facts hack])
      expect(playbook).not_to be_valid
      expect(playbook.errors[:capabilities]).to be_present
    end

    it "strips blank entries and duplicates, storing strings" do
      playbook = build(:ai_playbook, capabilities: ["", :account_facts, "account_facts", " ", "past_tickets"])
      playbook.validate
      expect(playbook.capabilities).to eq(%w[account_facts past_tickets])
    end

    it "does not require respond capabilities in triage_only mode" do
      expect(build(:ai_playbook, :triage_only, capabilities: %w[investigate_note])).to be_valid
      expect(build(:ai_playbook, :triage_only, capabilities: [])).to be_valid
    end

    it "#capability? checks the enabled keys" do
      playbook = build(:ai_playbook, capabilities: %w[account_facts])
      expect(playbook.capability?(:account_facts)).to be(true)
      expect(playbook.capability?("past_tickets")).to be(false)
    end

    it "#capabilities_for delegates to the registry per step" do
      playbook = build(:ai_playbook, capabilities: %w[account_facts similar_tickets suggest_articles])
      expect(playbook.capabilities_for(:respond).map(&:key)).to contain_exactly(:account_facts, :suggest_articles)
      expect(playbook.capabilities_for(:investigate).map(&:key)).to contain_exactly(:account_facts, :similar_tickets)
    end
  end

  describe "#move!" do
    let!(:first) { create(:ai_playbook) }
    let!(:second) { create(:ai_playbook) }
    let!(:third) { create(:ai_playbook) }
    let!(:default) { create(:ai_playbook, :default) }

    def order = described_class.where(is_default: false).ordered.to_a

    it "appends new playbooks after existing ones" do
      expect(order).to eq([first, second, third])
    end

    it "swaps with the neighbour" do
      expect(third.move!(:up)).to be(true)
      expect(order).to eq([first, third, second])
      expect(first.move!(:down)).to be(true)
      expect(order).to eq([third, first, second])
    end

    it "returns false at the edges" do
      expect(first.move!(:up)).to be(false)
      expect(third.move!(:down)).to be(false)
      expect(order).to eq([first, second, third])
    end

    it "never moves the default" do
      expect(default.move!(:up)).to be(false)
      expect(default.move!(:down)).to be(false)
    end
  end

  describe ".listed" do
    it "puts the default last" do
      default = create(:ai_playbook, :default)
      custom = create(:ai_playbook)
      expect(described_class.listed.to_a).to eq([custom, default])
    end
  end

  describe ".match_for" do
    let(:ticket) { create(:ticket, category: :billing, priority: 3) }

    it "returns nil when nothing exists" do
      expect(described_class.match_for(ticket)).to be_nil
    end

    it "matches a playbook with no conditions" do
      playbook = create(:ai_playbook)
      expect(described_class.match_for(ticket)).to eq(playbook)
    end

    it "matches on category" do
      create(:ai_playbook, category_keys: ["technical_issue"])
      billing = create(:ai_playbook, category_keys: ["billing"])
      expect(described_class.match_for(ticket)).to eq(billing)
    end

    it "respects priority bounds" do
      create(:ai_playbook, min_priority: 4)
      create(:ai_playbook, max_priority: 2)
      inside = create(:ai_playbook, min_priority: 2, max_priority: 3)
      expect(described_class.match_for(ticket)).to eq(inside)
    end

    it "uses the priority argument over the ticket priority" do
      high = create(:ai_playbook, min_priority: 5)
      expect(described_class.match_for(ticket)).to be_nil
      expect(described_class.match_for(ticket, priority: 5)).to eq(high)
    end

    describe "audience" do
      let(:audience) { create(:audience) }
      let!(:playbook) { create(:ai_playbook, audience: audience) }

      it "matches when the requester matches the audience" do
        allow_any_instance_of(Audience).to receive(:matches?).and_return(true)
        expect(described_class.match_for(ticket)).to eq(playbook)
      end

      it "skips when the requester does not match" do
        allow_any_instance_of(Audience).to receive(:matches?).and_return(false)
        expect(described_class.match_for(ticket)).to be_nil
      end
    end

    it "falls back to the default when nothing else matches" do
      create(:ai_playbook, category_keys: ["other"])
      default = create(:ai_playbook, :default)
      expect(described_class.match_for(ticket)).to eq(default)
    end

    it "prefers a matching non-default over the default" do
      create(:ai_playbook, :default, position: 0)
      specific = create(:ai_playbook, position: 5)
      expect(described_class.match_for(ticket)).to eq(specific)
    end

    it "returns nil when the default is disabled and nothing matches" do
      create(:ai_playbook, :default, :disabled)
      expect(described_class.match_for(ticket)).to be_nil
    end

    it "ignores disabled playbooks" do
      create(:ai_playbook, :disabled)
      expect(described_class.match_for(ticket)).to be_nil
    end

    it "orders by position then id" do
      create(:ai_playbook, position: 2)
      first = create(:ai_playbook, position: 1)
      expect(described_class.match_for(ticket)).to eq(first)
    end
  end
end
