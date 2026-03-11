module Adminit
  module Tickets
    class Finish
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ActiveRecord::Base.transaction do
          ticket.finish!

          ticket.notes.create!(
            account: account,
            kind: :system,
            body: "Ticket marked as finished."
          )
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
