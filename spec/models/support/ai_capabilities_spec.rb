require "rails_helper"

RSpec.describe Support::AiCapabilities do
  let(:registry) { described_class }

  let(:expected_keys) do
    %i[
      account_facts past_tickets search_articles similar_tickets vision_attachments investigate_note
      auto_set_priority auto_correct_category draft_replies
    ]
  end

  describe "declarations" do
    it "declares exactly the nine capabilities" do
      expect(registry.keys).to match_array(expected_keys)
    end

    it "drops the retired action capabilities (outcomes are JSON fields now)" do
      expect(registry.keys).not_to include(:suggest_articles, :propose_resolution, :request_human)
    end

    it "uses only known kinds and steps" do
      registry.all.each do |capability| # rubocop:disable Rails/FindEach
        expect(registry::KINDS).to include(capability.kind)
        expect(capability.steps - registry::STEPS).to be_empty
      end
    end

    it "classifies context, tool and flag capabilities" do
      expect(registry.all.select(&:context?).map(&:key)).to eq(%i[account_facts past_tickets])
      expect(registry.all.select(&:tool?).map(&:key)).to eq(%i[search_articles])
      expect(registry.all.select(&:flag?).map(&:key)).to include(:similar_tickets, :investigate_note, :auto_set_priority)
    end

    it "stores tool_class as a name, never a constant, only on tools" do
      expect(registry.all.map(&:tool_class).compact).to all(be_a(String))
      expect(registry.all.select(&:tool_class).map(&:kind).uniq).to eq([:tool])
    end

    it "marks the safe set as default" do
      expect(registry.defaults.map(&:key)).to match_array(%i[account_facts past_tickets search_articles investigate_note auto_set_priority])
    end

    it "has an en and es label and description for every key" do
      %i[en es].each do |locale|
        registry.keys.each do |key|
          expect(I18n.t("support_ai.capabilities.#{key}.label", locale: locale, raise: true)).to be_present
          expect(I18n.t("support_ai.capabilities.#{key}.description", locale: locale, raise: true)).to be_present
        end
      end
    end
  end

  describe "registry" do
    it "reports registration" do
      expect(registry.registered?(:account_facts)).to be(true)
      expect(registry.registered?("account_facts")).to be(true)
      expect(registry.registered?(:nope)).to be(false)
    end

    it "rejects invalid declarations" do
      expect { registry.register(key: :x, kind: :action, steps: [:respond]) }.to raise_error(ArgumentError)
      expect { registry.register(key: :x, kind: :flag, steps: [:bogus]) }.to raise_error(ArgumentError)
      expect { registry.register(key: :x, kind: :flag, steps: [:investigate]) }.to raise_error(ArgumentError)
    end

    describe ".for_step" do
      it "returns only enabled capabilities allowed in the step" do
        keys = registry.for_step(:respond, %w[account_facts investigate_note search_articles]).map(&:key)
        expect(keys).to contain_exactly(:account_facts, :search_articles)
      end

      it "ignores unknown keys" do
        expect(registry.for_step(:respond, %w[ghost suggest_articles])).to be_empty
      end

      it "accepts a step given as a string" do
        expect(registry.for_step("draft", %w[draft_replies]).map(&:key)).to eq([:draft_replies])
      end
    end
  end

  describe "security boundary" do
    it "never offers similar_tickets to the user-facing respond step" do
      expect(registry.fetch(:similar_tickets)).to be_flag
      expect(registry.fetch(:similar_tickets).steps).to eq([:handle])
      expect(registry.for_step(:respond, registry.keys.map(&:to_s)).map(&:key)).not_to include(:similar_tickets)
    end

    it "has no tool capability that reads other users' data" do
      expect(registry.all.select(&:tool?).map(&:key)).to eq(%i[search_articles])
    end
  end
end
