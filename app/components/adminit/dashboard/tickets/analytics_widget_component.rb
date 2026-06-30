module Adminit
  module Dashboard
    module Tickets
      class AnalyticsWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-2"

        option :account

        def title
          I18n.t("adminit.dashboard_widgets.tickets.analytics.title")
        end

        def stats
          @stats ||= ::TicketStatsQuery.call
        end

        def chart_height
          Adminit::DashboardHelper::CHART_HEIGHT
        end

        def chart_options
          ::Dashboard::ChartOptions.column(
            categories: status_labels,
            series: [{name: I18n.t("adminit.dashboard_widgets.tickets.analytics.series_name"), data: status_series}],
            semantic_colors: status_colors
          )
        end

        private

        def status_labels
          stats[:by_status].keys.map { |s| I18n.t("enums.ticket.status.#{s}") }
        end

        def status_series
          stats[:by_status].values
        end

        def status_colors
          stats[:by_status].keys.map { |s| Adminit::DashboardHelper::CHART_STATUS_COLORS[s.to_sym] || :primary }
        end
      end
    end
  end
end
