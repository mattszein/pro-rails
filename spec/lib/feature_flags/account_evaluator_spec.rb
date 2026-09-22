require "rails_helper"

RSpec.describe FeatureFlags::AccountEvaluator do
  describe "#enabled?" do
    it "is false for a nil account (S13)" do
      evaluator = described_class.new(nil)

      with_feature_flag(:some_flag) do
        expect(evaluator.enabled?(:some_flag)).to be false
      end
    end

    it "is false for a closed account (S14)" do
      account = create(:account, :closed)
      evaluator = described_class.new(account)

      with_feature_flag(:some_flag) do
        expect(evaluator.enabled?(:some_flag)).to be false
      end
    end

    it "is false for an unverified account with an explicit allow (S6, S8) — verification is not checked here" do
      account = create(:account) # unverified
      with_feature_flag(:some_flag) do
        flag = create(:feature_flag, key: "some_flag")
        create(:feature_flag_account, :allowed, feature_flag: flag, account: account)

        expect(described_class.new(account).enabled?(:some_flag)).to be true
      end
    end

    it "raises UnknownFlagError for an undeclared key outside production (S15)" do
      account = create(:account)
      evaluator = described_class.new(account)

      expect { evaluator.enabled?(:totally_undeclared_key) }
        .to raise_error(FeatureFlags::UnknownFlagError)
    end

    it "is false when the key is declared but has no feature_flags row (S1)" do
      account = create(:account)
      evaluator = described_class.new(account)

      with_feature_flag(:no_row_yet) do
        expect(evaluator.enabled?(:no_row_yet)).to be false
      end
    end

    it "delegates to FeatureFlag#grants? once a row exists" do
      account = create(:account, :with_role)

      with_feature_flag(:matching_flag) do
        flag = create(:feature_flag, key: "matching_flag")
        create(:feature_flag_audience, feature_flag: flag, audience: create(:audience))

        expect(described_class.new(account).enabled?(:matching_flag)).to be true
      end
    end

    it "is false and logs, rather than raising, when evaluation fails unexpectedly (S15)" do
      account = create(:account)
      evaluator = described_class.new(account)

      with_feature_flag(:boom_flag) do
        create(:feature_flag, key: "boom_flag")
        allow_any_instance_of(FeatureFlag).to receive(:grants?).and_raise("boom")

        expect(Rails.logger).to receive(:error)
        expect(evaluator.enabled?(:boom_flag)).to be false
      end
    end

    it "loads flags once per evaluator, regardless of how many keys are checked" do
      account = create(:account, :with_role)

      with_feature_flag(:flag_one, :flag_two, :flag_three) do
        create(:feature_flag, key: "flag_one")
        create(:feature_flag, key: "flag_two")
        create(:feature_flag, key: "flag_three")

        evaluator = described_class.new(account)
        evaluator.enabled?(:flag_one) # primes the memoized flag set

        query_count = 0
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
          query_count += 1 unless payload[:name] == "SCHEMA"
        end

        begin
          evaluator.enabled?(:flag_two)
          evaluator.enabled?(:flag_three)
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        expect(query_count).to eq(0)
      end
    end
  end
end
