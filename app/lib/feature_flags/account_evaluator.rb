module FeatureFlags
  # Raised for an undeclared flag key outside production — a mistake while
  # building and testing (PRODUCT-PLAN "Decision rules"). Not meant to be
  # rescued by callers; it signals a code bug (a typo'd key, a flag that was
  # never registered), not a runtime condition to handle.
  class UnknownFlagError < StandardError; end

  # For one account, answers "does this account have this flag" per the
  # decision rules in PRODUCT-PLAN.md. Built once per request (see
  # app/controllers/concerns/feature_gated.rb) and discarded with it.
  class AccountEvaluator
    def initialize(account)
      @account = account
    end

    # 1. No account -> false (S13 — a signed-out person never receives a
    #    flagged capability).
    # 2. Closed account -> false (S14). Unverified accounts are NOT rejected
    #    here — only the verified-users condition inspects verification, and
    #    an explicit allow must still work for an unverified account (S6, S8).
    # 3. Key not registered -> raise outside production (a mistake while
    #    building and testing); log and return false in production (S15).
    # 4. No feature_flags row for the key -> false (S1 for a newly declared
    #    flag that has not materialized yet, S15 for a removed one).
    # 5. Delegate to FeatureFlag#grants?.
    # 6. Any other exception -> log and return false (S15).
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

    # Loaded once per evaluator (per request), with associations preloaded,
    # so a render checking several flags for this account costs one query.
    def flags_by_key
      @flags_by_key ||= FeatureFlag.includes(:audiences, :account_entries).index_by(&:key)
    end

    def handle_unregistered_key(key)
      raise UnknownFlagError, "Unknown feature flag: #{key.inspect}" unless Rails.env.production?

      Rails.logger.warn("[FeatureFlags] unknown flag key: #{key.inspect}")
      false
    end
  end
end
