module Dashboard
  class WidgetRegistry
    Widget = Data.define(
      :key,
      :resource,
      :kind,
      :span,
      :policy_class,
      :component_class,
      :turbo_frame_id,
      :refresh_interval,
      :lazy
    )

    @widgets = {}

    class << self
      def register(**attrs)
        attrs[:refresh_interval] ||= nil
        attrs[:lazy] = true unless attrs.key?(:lazy)
        attrs[:span] ||= :full
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
