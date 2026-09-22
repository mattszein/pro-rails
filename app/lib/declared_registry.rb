# Shared store-and-reload mechanics for a registry of code-declared value
# objects (see app/lib/feature_flags/registry.rb, app/lib/audience_conditions/registry.rb
# and app/lib/dashboard/widget_registry.rb).
#
# Deliberately thin: this module owns only the keyed store and the reload
# lifecycle (`all`/`keys`/`registered?`/`reset!`). It does not define
# `register` or a reader method — each including registry keeps its own
# `register` (with whatever guards it needs) and its own reader name, because
# those differ per registry (Dashboard::WidgetRegistry#register enforces
# duplicate-key, refresh_interval and span rules that no other registry has;
# its reader is `find`, not `fetch`).
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
