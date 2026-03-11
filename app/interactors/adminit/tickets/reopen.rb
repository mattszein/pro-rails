module Adminit
  module Tickets
    class Reopen
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ActiveRecord::Base.transaction do
          ticket.reopen!

          ticket.notes.create!(
            account: account,
            kind: :system,
            body: "Admin reopened the ticket."
          )
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
