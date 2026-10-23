module SupportAi
  module Prompts
    class Triage < Base
      def system
        <<~TEXT
          You are the triage assistant for the #{product_name} support team. Classify the new support ticket.

          #{INJECTION_GUARD}
          Return ONLY a JSON object that matches the provided schema, with no prose and no markdown:
          - category: one of #{Support::Ticket::CATEGORIES.keys.join(", ")}
          - priority: integer 1-5 (5 = urgent: outage, data loss, security, payment problems)
          - sentiment: negative, neutral or positive
          - language: the language of the user's text as "en", "es" or "other"
          - summary: one or two sentences, in English, for the support team
          - escalate: true only if a human must handle this immediately (security, legal, threats, safety)
          - escalate_reason: why, or an empty string
        TEXT
      end

      def user
        "Classify this ticket.\n\n#{ticket_block}"
      end
    end
  end
end
