module Dashboard
  class WidgetRegistry
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

    @widgets = {}

    class << self
      def register(**attrs)
        attrs[:refresh_interval] ||= nil
        attrs[:lazy] = true unless attrs.key?(:lazy)
        attrs[:span] ||= :full
        attrs[:view_all_params] ||= nil
        widget = Widget.new(**attrs)

        raise ArgumentError, "duplicate widget key: #{widget.key}" if @widgets.key?(widget.key)
        if widget.refresh_interval && widget.refresh_interval < 15
          raise ArgumentError, "refresh_interval must be at least 15 seconds (got #{widget.refresh_interval})"
        end

        @widgets[widget.key] = widget
      end

      def all = @widgets.values
      def all_keys = @widgets.keys
      def find(key) = @widgets[key.to_sym]

      def for_keys(ks)
        keys = ks.map(&:to_sym).to_set
        all.select { |w| keys.include?(w.key) }
      end

      def for_resource(resource) = all.select { |w| w.resource == resource.to_sym }
      def clear = @widgets.clear
    end
  end
end
