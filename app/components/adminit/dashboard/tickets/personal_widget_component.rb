module Adminit
  module Dashboard
    module Tickets
      class PersonalWidgetComponent < ApplicationViewComponent
        include TableColumns

        option :account

        def tickets
          @tickets ||= Support::Ticket.assigned_open_for(account, limit: 10)
        end
      end
    end
  end
end
