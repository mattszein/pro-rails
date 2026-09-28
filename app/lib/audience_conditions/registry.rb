module AudienceConditions
  # In-memory store of the declared condition vocabulary — enumerable during
  # boot, migrations and asset builds, when no `audience_conditions` table
  # need exist.
  module Registry
    include DeclaredRegistry

    class << self
      def register(key:, type:, accepts:, predicate:)
        key = key.to_sym
        registry[key] = Condition.new(key: key, type: type, accepts: accepts, predicate: predicate)
      end

      def fetch(key) = registry.fetch(key.to_sym)
    end
  end
end
