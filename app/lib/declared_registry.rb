# Shared store-and-reload mechanics for a registry of code-declared value
# objects (see feature_flags/registry.rb, audience_conditions/registry.rb,
# dashboard/widget_registry.rb). Deliberately thin: only the keyed store and
# the reload lifecycle. `register` and any reader stay per-registry, since
# guards and naming differ between them.
module DeclaredRegistry
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def registry
      @registry ||= {}
    end

    def all = registry.values
    def keys = registry.keys
    def registered?(key) = registry.key?(key.to_sym)
    def reset! = registry.clear
  end
end
