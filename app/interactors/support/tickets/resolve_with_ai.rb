module Support
  module Tickets
    # "This solved it": the requester confirms the AI's fix. Finishes the ticket; the AI state
    # is sticky, so later reopen requests go to humans.
    class ResolveWithAi
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ticket.with_lock do
          ticket.resolve_with_ai!
          ticket.notes.create!(account: nil, kind: :system, body: "Resolved by the user with AI assistance.")
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
