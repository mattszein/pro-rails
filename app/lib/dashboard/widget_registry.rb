module Dashboard
  class WidgetRegistry
    include DeclaredRegistry

    Widget = Data.define(
      :key,
      :resource,
      :kind,
      :span,
      :policy_class,
      :component_class,
      :refresh_interval,
      :lazy,
      :view_all_params
    ) do
      def turbo_frame_id = "dashboard_#{key}"

      # Resolved on each call, never memoized: holding a Class across a dev code
      # reload pins a stale constant. Resolution lives here (not in callers) so
      # the allowlist (widgets.rb) and its dereference stay in one file.
      def policy = resolve(policy_class, ActionPolicy::Base)

      def component = resolve(component_class, ViewComponent::Base)

      private

      def resolve(name, expected_ancestor)
        klass = name.constantize
        raise TypeError, "#{name} is not a #{expected_ancestor}" unless klass < expected_ancestor
        klass
      end
    end

    class << self
      def register(**attrs)
        attrs[:refresh_interval] ||= nil
        attrs[:lazy] = true unless attrs.key?(:lazy)
        attrs[:span] ||= :full
        attrs[:view_all_params] ||= nil
        widget = Widget.new(**attrs)

        raise ArgumentError, "duplicate widget key: #{widget.key}" if registry.key?(widget.key)
        if widget.refresh_interval && widget.refresh_interval < 15
          raise ArgumentError, "refresh_interval must be at least 15 seconds (got #{widget.refresh_interval})"
        end

        # TabbedContainerComponent reads widgets.first.span for the whole card
        # (app/components/adminit/dashboard/tabbed_container_component.rb) —
        # a mismatched span within a resource would make the layout depend on
        # registration order.
        sibling = by_resource(widget.resource).first
        if sibling && sibling.span != widget.span
          raise ArgumentError, "widget :#{widget.key} has span #{widget.span.inspect}, but " \
                                "resource :#{widget.resource} is already registered with span #{sibling.span.inspect}"
        end

        registry[widget.key] = widget
      end

      def find(key) = registry[key.to_sym]

      # Widgets registered under any of the given keys; unknown keys are ignored.
      def find_all(keys)
        wanted = keys.map(&:to_sym).to_set
        all.select { |w| wanted.include?(w.key) }
      end

      # Widgets that belong to the given resource.
      def by_resource(resource) = all.select { |w| w.resource == resource.to_sym }
    end
  end
end
