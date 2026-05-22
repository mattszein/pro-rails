module Adminit
  module Dashboard
    module Tickets
      class AnalyticsWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-2"

        def initialize(account:)
          @account = account
        end

        def title
          I18n.t("adminit.dashboard_widgets.tickets.analytics.title")
        end

        def stats
          @stats ||= ::TicketStatsQuery.call
        end
      end
    end
  end
end
