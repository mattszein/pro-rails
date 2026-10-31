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
      keys = Support::AiCapabilities.keys.map(&:to_s)
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

    it "rejects the retired action keys (the migration strips them from stored playbooks)" do
      %w[suggest_articles propose_resolution request_human].each do |key|
        expect(build(:ai_playbook, capabilities: [key])).not_to be_valid
      end
    end

    it "#capabilities_for delegates to the registry per step" do
      playbook = build(:ai_playbook, capabilities: %w[account_facts similar_tickets search_articles])
      expect(playbook.capabilities_for(:respond).map(&:key)).to contain_exactly(:account_facts, :search_articles)
      expect(playbook.capabilities_for(:handle).map(&:key)).to contain_exactly(:account_facts, :similar_tickets, :search_articles)
    end
  end

  describe ".listed" do
    it "orders custom playbooks by name and puts the default last" do
      default = create(:ai_playbook, :default, name: "A default")
      zed = create(:ai_playbook, name: "Zed")
      alpha = create(:ai_playbook, name: "Alpha")
      expect(described_class.listed.to_a).to eq([alpha, zed, default])
    end
  end

  describe "#specificity" do
    it "counts the conditions that are set" do
      expect(build(:ai_playbook).specificity).to eq(0)
      expect(build(:ai_playbook, category_keys: ["billing"]).specificity).to eq(1)
      expect(build(:ai_playbook, min_priority: 2).specificity).to eq(1)
      expect(build(:ai_playbook, min_priority: 2, max_priority: 4).specificity).to eq(1)
      expect(build(:ai_playbook, audience: create(:audience)).specificity).to eq(1)
      expect(build(:ai_playbook, category_keys: %w[billing other], max_priority: 4, audience: create(:audience)).specificity).to eq(3)
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
      create(:ai_playbook, :default)
      specific = create(:ai_playbook)
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

    it "picks the most specific matching playbook" do
      create(:ai_playbook)
      create(:ai_playbook, category_keys: ["billing"])
      specific = create(:ai_playbook, category_keys: ["billing"], min_priority: 2)
      expect(described_class.match_for(ticket)).to eq(specific)
    end

    it "breaks ties with the oldest playbook" do
      oldest = create(:ai_playbook, category_keys: ["billing"])
      create(:ai_playbook, max_priority: 4)
      expect(described_class.match_for(ticket)).to eq(oldest)
    end

    it "ignores a more specific playbook that is disabled" do
      create(:ai_playbook, :disabled, category_keys: ["billing"], min_priority: 2)
      general = create(:ai_playbook)
      expect(described_class.match_for(ticket)).to eq(general)
    end

    it "ignores a more specific playbook that does not match" do
      create(:ai_playbook, category_keys: ["other"], min_priority: 1, max_priority: 2)
      general = create(:ai_playbook)
      expect(described_class.match_for(ticket)).to eq(general)
    end
  end

  describe "#snapshot" do
    it "freezes the rules a run used, including the audience name" do
      audience = create(:audience, name: "VIPs")
      playbook = create(:ai_playbook, name: "Billing", categories: [Support::Ticket::CATEGORIES[:billing]],
        min_priority: 2, max_priority: 4, audience: audience, instructions: "Be kind")

      expect(playbook.snapshot).to eq(
        name: "Billing",
        mode: "assist",
        capabilities: playbook.capabilities,
        instructions: "Be kind",
        max_ai_turns: playbook.max_ai_turns,
        idle_reminder_after_hours: playbook.idle_reminder_after_hours,
        idle_handoff_after_hours: playbook.idle_handoff_after_hours,
        categories: ["billing"],
        min_priority: 2,
        max_priority: 4,
        audience: "VIPs",
        is_default: false
      )
    end

    it "has a nil audience when none is set" do
      expect(build(:ai_playbook, audience: nil).snapshot[:audience]).to be_nil
    end
  end
end
