module Adminit
  module Dashboard
    module Permissions
      class OverviewWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        option :account

        def title
          I18n.t("adminit.dashboard_widgets.permissions.overview.title")
        end

        def stats
          @stats ||= ::PermissionStatsQuery.call
        end
      end
    end
  end
end
