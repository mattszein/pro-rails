module Support
  module Tickets
    # The requester asks for a person while the AI is engaged. Hands off immediately (an
    # in-flight AI run then discards itself), then writes the summary note (LLM call, falls
    # back to a plain note).
    class RequestHuman
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        was_analyzing = false
        ticket.with_lock do
          was_analyzing = ticket.ai_analyzing?
          ticket.request_ai_handoff!
        end

        Support::Ai::Typing.hide(ticket) if was_analyzing
        Support::Ai::HandoffNote.call(ticket: ticket, reason: "user requested a human")
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
