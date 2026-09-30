module FeatureFlagsHelper
  # Registers one or more flag keys for the duration of the block, then
  # restores the registry to what it held before — so a spec that needs a
  # flag no production code declares doesn't leak it into later examples.
  def with_feature_flag(*keys)
    original = FeatureFlags::Registry.registry.dup
    keys.each { |key| FeatureFlags::Registry.register(key) }
    yield
  ensure
    FeatureFlags::Registry.registry.replace(original)
  end
end
