module Support
  module Ai
    # Last resort when the assistant cannot finish (retries exhausted, no playbook): hand the
    # ticket to a human with a generic message so the user is never left waiting. Idempotent:
    # does nothing unless the AI still owns the ticket.
    class Fallback
      include Interactor

      delegate :ticket, to: :context

      def call
        ticket.with_lock do
          next unless ticket.ai_analyzing? || ticket.ai_awaiting_user?

          ticket.request_ai_handoff!
          ticket.conversation.messages.create!(sender: :ai, account: nil, content: I18n.t("support.ai.handoff_message"), metadata: {})
          ticket.notes.create!(account: nil, kind: :system, body: note_body)
          RecordRun.call(ticket: ticket, playbook: ticket.ai_playbook, trigger: :fallback, step: :respond, error: context.error || context.reason || "AI failed after retries")
        end
      ensure
        Typing.hide(ticket)
      end

      private

      def note_body
        context.reason ? "AI unavailable (#{context.reason}); handed off" : "AI failed after retries; handed off"
      end
    end
  end
end
