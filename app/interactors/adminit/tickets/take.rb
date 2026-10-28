module Adminit
  module Tickets
    class Take
      include Interactor

      delegate :ticket, :account, to: :context

      def call
        ActiveRecord::Base.transaction do
          # Row lock + re-check closes the race where two admins take the same ticket.
          ticket.lock!
          context.fail!(error: I18n.t("adminit.tickets.already_assigned")) unless ticket.assigned_id.nil?

          # Recorded BEFORE the update: the model callback releases the AI on assignment.
          was_engaged = ticket.ai_engaged?

          ticket.update!(assigned: account, status: :in_progress)
          ticket.notes.create!(account: account, kind: :system, body: "Ticket taken and assigned.")
          ticket.notes.create!(account: nil, kind: :system, body: "AI stepped back.") if was_engaged
        end
      rescue Support::Ticket::InvalidTransition, ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end
    end
  end
end
