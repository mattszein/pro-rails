module Adminit
  module Tickets
    class RejectReopen
      include Interactor

      delegate :ticket, :account, :body, to: :context

      def call
        ActiveRecord::Base.transaction do
          ticket.reject_reopen!
          
          note_body = "Admin rejected the reopen request. Status changed to closed."
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
