module FeatureFlags
  # In-memory store of declared flag keys. Depends on nothing but Ruby —
  # enumerable during boot, migrations and asset builds, when no
  # `feature_flags` table need exist.
  module Registry
    include DeclaredRegistry

    class << self
      def register(key)
        key = key.to_sym
        registry[key] = Flag.new(key: key)
      end

      def fetch(key) = registry.fetch(key.to_sym)
    end
  end
end
