module Adminit
  module Dashboard
    module Tickets
      class PersonalWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        def initialize(account:)
          @account = account
        end

        def title
          I18n.t("adminit.dashboard_widgets.tickets.personal.title")
        end

        def tickets
          @tickets ||= ::TicketsForAccountQuery.call(account: @account, limit: 10)
        end

        def view_all_path
          helpers.adminit_tickets_path(assignee: "me")
        end

        def view_all_label
          I18n.t("adminit.dashboard_widgets.tickets.personal.view_all")
        end
      end
    end
  end
end
