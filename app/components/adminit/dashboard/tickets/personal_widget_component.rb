module Adminit
  module Dashboard
    module Tickets
      class PersonalWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        option :account

        def tickets
          @tickets ||= ::TicketsForAccountQuery.call(account: account, limit: 10)
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
