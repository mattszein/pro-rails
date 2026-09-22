module AudienceConditionsHelper
  # Registers a spec-only condition for the duration of the block, then
  # restores the registry to what it held before.
  def with_audience_condition(key, type:, accepts:, predicate:, scope: ->(relation, value) { raise NotImplementedError })
    original = AudienceConditions::Registry.registry.dup
    AudienceConditions::Registry.register(key: key, type: type, accepts: accepts, predicate: predicate, scope: scope)
    yield
  ensure
    AudienceConditions::Registry.registry.replace(original)
  end
end
