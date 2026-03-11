module Support
  class ReopenFormComponent < ApplicationViewComponent
    option :ticket

    def render?
      ticket.finished?
    end
  end
end
