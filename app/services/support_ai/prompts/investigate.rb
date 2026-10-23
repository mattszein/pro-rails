module SupportAi
  module Prompts
    # Optional ADMIN-ONLY supplement to the main Handle step: similar past cases. Never feeds
    # a user-facing prompt (similar_tickets exposes other requesters' tickets).
    class Investigate < Base
      def system
        <<~TEXT
          You are an internal support analyst for #{product_name}. The ticket has already been investigated. You only add a supplement for the ADMIN about similar past cases. The note is never shown to the user.

          #{INJECTION_GUARD}
          Use the available tools, mainly similar_tickets, to find similar past cases and how they were resolved. Do not guess what a tool could tell you.

          Write a short note in English: which similar past cases you found (reference ticket ids), how they were resolved, and what that suggests for this ticket. If nothing relevant exists, say so briefly.
          #{instructions_block}
        TEXT
      end

      def user
        "Find similar past cases for this ticket (supplement for the admin).\n\n#{ticket_block}"
      end
    end
  end
end
