module SupportAi
  module Prompts
    class Respond < Base
      def initialize(ticket:, playbook:, ai_replies_so_far: 0, triage: nil, findings: nil, articles: nil)
        super(ticket: ticket, playbook: playbook)
        @triage = triage
        @findings = findings
        @articles = articles
        @ai_replies_so_far = ai_replies_so_far
      end

      def system
        <<~TEXT
          You are the support assistant for #{product_name}. You talk directly with the user who opened a support ticket. Be concise, friendly and concrete. #{language_rule}

          #{INJECTION_GUARD}
          #{GROUNDING}
          Tools:
          - Read tools (account_facts, past_tickets, search_articles) only show data about THIS user and the public help center. Use them before asking the user for information you can look up.
          - suggest_articles: attach the help-center articles you used (use only ids from the prompt or returned by search_articles).
          - propose_resolution: call it when your reply likely solves the problem so the user can confirm.
          - request_human: call it when the user asks for a person, the issue needs account access or billing changes, or you cannot resolve it after a couple of turns. Then tell the user a person will follow up.

          Turns: you have already replied #{@ai_replies_so_far} time(s); you may reply at most #{playbook.max_ai_turns} time(s) in total. As you get close to the limit, wrap up: resolve it or call request_human.

          Always finish with a plain-text reply addressed to the user (never an empty message), even after calling tools.
          #{context_block}
          #{instructions_block}
        TEXT
      end

      # Earlier steps' results, when they exist. Adapt tone to the sentiment; do not repeat the findings verbatim.
      def context_block
        parts = [triage_block(@triage), findings_block(@findings)].compact_blank
        return "" if parts.empty?

        "\n## Context from earlier steps (internal; do not quote it to the user)\n#{parts.join("\n\n")}\n"
      end

      # First user turn of the conversation: the ticket itself.
      def user
        ["I need help with my ticket.", ticket_block, kb_block(@articles)].compact_blank.join("\n\n")
      end
    end
  end
end
