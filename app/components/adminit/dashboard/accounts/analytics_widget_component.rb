module Adminit
  module Dashboard
    module Accounts
      class AnalyticsWidgetComponent < ApplicationViewComponent
        option :account

        def stats
          @stats ||= Account.dashboard_stats
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
