module Adminit
  module Tickets
    class AcceptReopen
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ActiveRecord::Base.transaction do
          ticket.accept_reopen!

          ticket.notes.create!(
            account: account,
            kind: :system,
            body: "Admin accepted the reopen request. Status changed to reopened."
          )
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
