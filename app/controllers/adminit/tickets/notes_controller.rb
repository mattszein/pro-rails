module Adminit
  module Tickets
    class NotesController < Adminit::ApplicationController
      before_action :set_ticket

      def create
        authorize! @ticket, to: :update?, with: Adminit::TicketPolicy
        
        @note = @ticket.notes.build(note_params)
        @note.account = current_account
        @note.kind = :internal

        if @note.save
          redirect_to adminit_ticket_path(@ticket), notice: "Note added."
        else
          redirect_to adminit_ticket_path(@ticket), alert: "Note could not be added: #{@note.errors.full_messages.join(", ")}"
        end
      end

      private

      def set_ticket
        @ticket = Support::Ticket.find(params[:ticket_id])
      end

      def note_params
        params.require(:support_note).permit(:body)
      end
    end
  end
end
