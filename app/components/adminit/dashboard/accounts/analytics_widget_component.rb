module Adminit
  module Dashboard
    module Accounts
      class AnalyticsWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-2"

        option :account

        def title
          I18n.t("adminit.dashboard_widgets.accounts.analytics.title")
        end

        def stats
          @stats ||= ::AccountStatsQuery.call
        end

        def chart_height
          Adminit::DashboardHelper::CHART_HEIGHT
        end

        def chart_options
          ::Dashboard::ChartOptions.area(
            categories: month_labels,
            series: [{name: I18n.t("adminit.dashboard_widgets.accounts.analytics.series_name"), data: month_values}],
            semantic_colors: ["primary"]
          )
        end

        private

        def month_labels
          stats[:by_month].keys.map { |month| I18n.l(month, format: "%b %Y") }
        end

        def month_values
          stats[:by_month].values
        end
      end
    end
  end
end
