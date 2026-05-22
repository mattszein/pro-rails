module Adminit
  module Dashboard
    module Tickets
      class GeneralWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        def initialize(account:)
          @account = account
        end

        def title
          I18n.t("adminit.dashboard_widgets.tickets.general.title")
        end

        def tickets
          @tickets ||= Support::Ticket.open.order(updated_at: :desc).limit(10)
        end

        def view_all_path
          helpers.adminit_tickets_path
        end

        def view_all_label
          I18n.t("adminit.dashboard_widgets.tickets.general.view_all")
        end
      end
    end
  end
end
