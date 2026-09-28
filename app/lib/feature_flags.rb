# Public entry points to the decision: the only supported way to ask whether
# an account has a capability. Never call either from a model, a migration,
# or a job/broadcast path that writes — those have no request account.
module FeatureFlags
  # Bind one account for repeated questions in a request.
  def self.for(account)
    AccountEvaluator.new(account)
  end

  # One-off check; prefer `.for(account)` when checking several flags.
  def self.enabled?(key, account)
    self.for(account).enabled?(key)
  end
end
