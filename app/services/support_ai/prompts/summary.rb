module SupportAi
  module Prompts
    class Summary < Base
      def initialize(ticket:, playbook:, transcript: [])
        super(ticket: ticket, playbook: playbook)
        @transcript = transcript
      end

      def system
        <<~TEXT
          You write handoff summaries for the #{product_name} support team. A human agent is taking over a ticket and has not read the conversation.

          #{INJECTION_GUARD}
          Write a short factual note in English: 1-2 sentences, at most 50 words, covering what the user asked and what the user added during the conversation. Do NOT judge or critique earlier replies. Do NOT give a next step or recommendation. Do NOT guess at features, policies or causes. No greetings, no markdown headings.
          #{instructions_block}
        TEXT
      end

      def user
        lines = @transcript.map { |speaker, text| untrusted(speaker, text) }
        "Summarize this ticket for the agent taking over.\n\n#{ticket_block}\n\nConversation so far:\n#{lines.join("\n")}"
      end
    end
  end
end
