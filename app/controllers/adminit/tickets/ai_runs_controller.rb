module Adminit
  module Tickets
    # Read-only viewer for one AI run (prompt/tool transcript), opened in the modal frame.
    class AiRunsController < Adminit::ApplicationController
      before_action :set_ticket
      before_action :ensure_frame_response

      def show
        authorize! @ticket, to: :show?, with: Adminit::TicketPolicy
        @run = @ticket.ai_runs.includes(:playbook).find(params[:id])
      end

      private

      def set_ticket
        @ticket = Support::Ticket.find(params[:ticket_id])
      end
    end
  end
end
