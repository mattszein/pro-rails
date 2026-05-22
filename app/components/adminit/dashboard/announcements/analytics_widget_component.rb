module Adminit
  module Dashboard
    module Announcements
      class AnalyticsWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        def initialize(account:)
          @account = account
        end

        def title
          I18n.t("adminit.dashboard_widgets.announcements.analytics.title")
        end

        def stats
          @stats ||= ::AnnouncementStatsQuery.call
        end
      end
    end
  end
end
