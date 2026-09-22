# Public entry points to the decision. `FeatureFlags.for` and
# `FeatureFlags.enabled?` are the only supported way to ask whether an
# account has a capability — see the implementation constraints in
# TECH-PLAN.md §9. Never call either from a model, a migration, a job that
# writes, or a broadcast path: those callers have no request account, and an
# answer that varies by caller context makes the same record behave
# differently depending on which code touched it.
module FeatureFlags
  # Bind one account for repeated questions in a request — a page checking
  # several flags issues one query instead of one per flag. Build fresh per
  # request and discard it with the request; never hold one in a constant,
  # a class variable, a thread-local, or any process-lifetime cache.
  def self.for(account)
    AccountEvaluator.new(account)
  end

  # One-off entry point for callers holding no evaluator. Delegates to a
  # fresh AccountEvaluator — prefer `.for(account)` when checking more than
  # one flag for the same account in one render.
  def self.enabled?(key, account)
    self.for(account).enabled?(key)
  end
end
