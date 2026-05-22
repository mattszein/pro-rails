module Adminit
  module Dashboard
    module Announcements
      class GeneralWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        def initialize(account:)
          @account = account
        end

        def title
          I18n.t("adminit.dashboard_widgets.announcements.general.title")
        end

        def announcements
          @announcements ||= Announcement.order(updated_at: :desc).limit(5)
        end

        def view_all_path
          helpers.adminit_announcements_path
        end

        def view_all_label
          I18n.t("adminit.dashboard_widgets.announcements.general.view_all")
        end
      end
    end
  end
end
