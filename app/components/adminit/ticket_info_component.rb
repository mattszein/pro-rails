module Adminit
  class TicketInfoComponent < ApplicationViewComponent
    option :ticket

    def status_theme
      helpers.ticket_status_theme(ticket.status)
    end
  end
end
