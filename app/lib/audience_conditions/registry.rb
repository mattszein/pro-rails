module AudienceConditions
  # In-memory store of the declared condition vocabulary. Depends on nothing
  # but Ruby — enumerable during boot, migrations and asset builds, when no
  # `audience_conditions` table need exist.
  module Registry
    include DeclaredRegistry

    class << self
      def register(key:, type:, accepts:, predicate:, scope:)
        key = key.to_sym
        registry[key] = Condition.new(key: key, type: type, accepts: accepts, predicate: predicate, scope: scope)
      end

      def fetch(key) = registry.fetch(key.to_sym)
    end
  end
end
