# Entry point for flag checks. Not for models, migrations, or writing jobs: they have no request account.
module FeatureFlags
  # Evaluator bound to one account, for several checks in a request.
  def self.for(account)
    AccountEvaluator.new(account)
  end

  # Single check; use `.for(account)` when checking several flags.
  def self.enabled?(key, account)
    self.for(account).enabled?(key)
  end
end
