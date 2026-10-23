require "rails_helper"

RSpec.describe SupportAi::Capabilities do
  let(:registry) { SupportAi::Capabilities::Registry }

  let(:expected_keys) do
    %i[
      account_facts past_tickets similar_tickets search_articles vision_attachments investigate_note
      auto_set_priority auto_correct_category suggest_articles propose_resolution request_human draft_replies
    ]
  end

  describe "declarations" do
    it "declares exactly the twelve capabilities" do
      expect(registry.keys).to match_array(expected_keys)
    end

    it "uses only known kinds and steps" do
      registry.all.each do |capability| # rubocop:disable Rails/FindEach
        expect(registry::KINDS).to include(capability.kind)
        expect(capability.steps - registry::STEPS).to be_empty
      end
    end

    it "stores tool_class as a name, never a constant" do
      expect(registry.all.map(&:tool_class).compact).to all(be_a(String))
    end

    it "marks the safe set as default" do
      expect(registry.defaults.map(&:key)).to match_array(
        %i[account_facts past_tickets search_articles suggest_articles propose_resolution request_human investigate_note auto_set_priority]
      )
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

  describe "Registry" do
    it "reports registration" do
      expect(registry.registered?(:account_facts)).to be(true)
      expect(registry.registered?("account_facts")).to be(true)
      expect(registry.registered?(:nope)).to be(false)
    end

    it "rejects invalid declarations" do
      expect { registry.register(key: :x, kind: :write, steps: [:respond]) }.to raise_error(ArgumentError)
      expect { registry.register(key: :x, kind: :read, steps: [:bogus]) }.to raise_error(ArgumentError)
    end

    describe ".for_step" do
      it "returns only enabled capabilities allowed in the step" do
        keys = registry.for_step(:respond, %w[account_facts investigate_note suggest_articles]).map(&:key)
        expect(keys).to contain_exactly(:account_facts, :suggest_articles)
      end

      it "ignores unknown keys" do
        expect(registry.for_step(:respond, %w[ghost])).to be_empty
      end

      it "accepts a step given as a string" do
        expect(registry.for_step("draft", %w[draft_replies]).map(&:key)).to eq([:draft_replies])
      end
    end
  end

  describe "security boundary" do
    it "never lists similar_tickets outside :investigate" do
      expect(registry.fetch(:similar_tickets).steps).to eq([:investigate])
    end

    it "excludes similar_tickets from the user-facing respond step" do
      expect(registry.for_step(:respond, registry.keys.map(&:to_s)).map(&:key)).not_to include(:similar_tickets)
    end

    it "keeps cross-user read capabilities out of :respond" do
      cross_user_reads = %i[similar_tickets]
      cross_user_reads.each do |key|
        capability = registry.fetch(key)
        expect(capability.kind).to eq(:read)
        expect(capability.steps).not_to include(:respond)
      end
    end
  end
end
