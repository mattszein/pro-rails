module Support
  module Tickets
    class RequestReopen
      include Interactor

      delegate :ticket, :account, :body, to: :context

      def call
        ActiveRecord::Base.transaction do
          ticket.request_reopen!
          
          # Create the message with the reason for reopening
          ticket.conversation.messages.create!(
            account: account,
            content: body
          )

          # Create a system note for the transition
          ticket.notes.create!(
            kind: :system,
            body: "User requested to reopen the ticket."
          )
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
