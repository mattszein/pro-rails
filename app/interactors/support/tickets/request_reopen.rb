module Support
  module Tickets
    class RequestReopen
      include Interactor

      delegate :ticket, :account, :body, to: :context

      def call
        ActiveRecord::Base.transaction do
          ticket.request_reopen!

          note_body = "User requested to reopen the ticket."
          note_body += " Reason: #{body}" if body.present?

          ticket.notes.create!(
            account: account,
            kind: :system,
            body: note_body
          )
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
