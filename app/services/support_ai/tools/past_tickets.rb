module SupportAi
  module Tools
    # The requester's own previous tickets (never anyone else's).
    class PastTickets < Base
      LIMIT = 10

      description "The requester's previous support tickets (up to 10, newest first): id, title, " \
        "category, status, date and whether it was finished. Takes no arguments."

      def execute
        tickets = Support::Ticket.history_for(ticket, limit: LIMIT).map do |past|
          {
            id: past.id,
            title: past.title.to_s.truncate(120),
            category: past.category,
            status: past.status,
            created_on: past.created_at.to_date.iso8601,
            finished: past.finished?
          }
        end
        {tickets: tickets}
      end
    end
  end
end
