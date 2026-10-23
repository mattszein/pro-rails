module SupportAi
  module Tools
    # ADMIN-FACING (investigate step only). Looks at other accounts' finished tickets, so it
    # returns the bare minimum: title, category and month. Never identity, description or messages.
    class SimilarTickets < Base
      LIMIT = 5

      description "Titles of finished tickets in the same category from other users that look similar. " \
        "Argument: query, a few keywords. Returns title, category and month only."

      parameter :query, description: "A few keywords describing the problem"

      def execute(query:)
        terms = query.to_s.scan(/[[:alnum:]]{3,}/).first(5)
        terms = ticket.title.to_s.scan(/[[:alnum:]]{3,}/).first(5) if terms.empty?

        tickets = Support::Ticket.resolved_similar_to(ticket, terms: terms, limit: LIMIT).map do |similar|
          {title: similar.title.to_s.truncate(120), category: similar.category, month: similar.created_at.strftime("%Y-%m")}
        end
        {tickets: tickets}
      end
    end
  end
end
