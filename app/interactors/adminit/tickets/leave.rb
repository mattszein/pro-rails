module Adminit
  module Tickets
    class Leave
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ActiveRecord::Base.transaction do
          if ticket.assigned_id == account.id
            ticket.update!(assigned: nil, status: :open)
            ticket.notes.create!(
              account: account,
              kind: :system,
              body: "Left the ticket. Status changed to open."
            )
          else
            context.fail!(error: I18n.t("adminit.tickets.not_assigned"))
          end
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
