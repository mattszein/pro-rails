module Adminit
  module Dashboard
    class TabbedContainerComponent < ApplicationViewComponent
      option :resource
      option :widgets, default: -> { [] }

      def container_span_class
        (@widgets.size > 1) ? "col-span-1 md:col-span-2" : "col-span-1"
      end

      def container_height_class
        has_chart? ? Adminit::DashboardHelper::WIDGET_HEIGHT_EXPANDED : Adminit::DashboardHelper::WIDGET_HEIGHT_SMALL
      end

      def tab_label(widget)
        I18n.t("adminit.dashboard.kinds.#{widget.kind}", default: widget.kind.to_s.humanize)
      end

      def submenu_sections
        widgets.each_with_index.map do |widget, i|
          Core::TabsComponent::Section.new(key: widget.kind, name: tab_label(widget), panel_id: i)
        end
      end

      attr_reader :widgets, :resource

      private

      def has_chart?
        widgets.any? { |w| w.kind == :analytics }
      end

      def widget_frame(widget)
        if widget.lazy
          helpers.turbo_frame_tag widget.turbo_frame_id,
            src: helpers.adminit_dashboard_widget_path(resource: widget.resource, kind: widget.kind),
            loading: :lazy,
            data: helpers.auto_refresh_data(widget) do
              render Adminit::Dashboard::SkeletonWidgetComponent.new(kind: widget.kind)
            end
        else
          render widget.component_class.constantize.new(account: helpers.current_account)
        end
      end
    end
  end
end
