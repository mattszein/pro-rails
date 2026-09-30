module FeatureFlags
  # Raised for an undeclared flag key outside production — signals a code
  # bug (a typo'd key, a flag never registered), not a runtime condition.
  class UnknownFlagError < StandardError; end

  # For one account, answers "does this account have this flag". Built once
  # per request (see app/controllers/concerns/feature_gated.rb) and
  # discarded with it.
  class AccountEvaluator
    def initialize(account)
      @account = account
    end

    def enabled?(key)
      return false if @account.nil?
      return false if @account.closed?

      key = key.to_sym
      return handle_unregistered_key(key) unless FeatureFlags::Registry.registered?(key)

      begin
        flag = flags_by_key[key.to_s]
        return false unless flag

        flag.grants?(@account)
      rescue => e
        Rails.logger.error("[FeatureFlags] evaluation of #{key} failed: #{e.class}: #{e.message}")
        false
      end
    end

    private

    # Loaded once per evaluator (per request): audiences with their
    # conditions, and only this account's own entries — so a render
    # checking several flags costs a fixed, small number of queries
    # regardless of how many other accounts hold entries on those flags.
    def flags_by_key
      @flags_by_key ||= begin
        flags = FeatureFlag.includes(audiences: :audience_conditions).to_a
        ActiveRecord::Associations::Preloader.new(
          records: flags,
          associations: :account_entries,
          scope: FeatureFlagAccount.where(account_id: @account.id)
        ).call
        flags.index_by(&:key)
      end
    end

    def handle_unregistered_key(key)
      raise UnknownFlagError, "Unknown feature flag: #{key.inspect}" unless Rails.env.production?

      Rails.logger.warn("[FeatureFlags] unknown flag key: #{key.inspect}")
      false
    end
  end
end
