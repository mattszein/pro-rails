module Adminit
  module Dashboard
    module Tickets
      class GeneralWidgetComponent < ApplicationViewComponent
        include TableColumns

        option :account

        def tickets
          @tickets ||= Support::Ticket.recent_open(limit: 10)
        end
      end
    end
  end
end
