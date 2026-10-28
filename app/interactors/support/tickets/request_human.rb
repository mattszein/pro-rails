module Support
  module Tickets
    # The requester asks for a person while the AI is engaged. Hands off immediately (an
    # in-flight AI run then discards itself) and leaves a system note for the agent who picks it up.
    class RequestHuman
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ticket.with_lock do
          ticket.request_ai_handoff!
          ticket.notes.create!(account: nil, kind: :system, body: "User requested a human")
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
