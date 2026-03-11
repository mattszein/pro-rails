module Adminit
  module Tickets
    class Take
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ActiveRecord::Base.transaction do
          if ticket.assigned_id.nil?
            ticket.update!(assigned: account, status: :in_progress)
            ticket.notes.create!(
              account: account,
              kind: :system,
              body: "Ticket taken and assigned."
            )
          else
            context.fail!(error: "Ticket already assigned.")
          end
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
