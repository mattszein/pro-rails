module Support
  module Ai
    # The `ai` note admins read first after a handoff. Built from an LLM summary of the
    # conversation; falls back to a plain pointer when the summary call fails, so a flaky
    # model never blocks a handoff. Call it OUTSIDE any lock or transaction (LLM call).
    module HandoffNote
      module_function

      def call(ticket:, reason:, playbook: nil)
        ticket.notes.create!(account: nil, kind: :ai, body: body_for(ticket, playbook || ticket.ai_playbook, reason))
      end

      def body_for(ticket, playbook, reason)
        playbook ||= Support::AiPlaybook.default_playbook
        raise SupportAi::Error, "No playbook to summarize with" unless playbook

        SupportAi::Responder.new(ticket: ticket, playbook: playbook).summarize.output
      rescue SupportAi::Error => e
        Rails.logger.warn("Support AI summary failed for ticket #{ticket.id}: #{e.message}")
        "AI handoff: #{reason.presence || "handoff requested"}. See conversation."
      end
    end
  end
end
