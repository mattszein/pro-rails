module Support
  class MessagesController < DashboardController
    before_action :require_account
    before_action :set_ticket

    def create
      @message = @conversation.messages.build(message_params)
      @message.account = current_account

      authorize! @message, to: :create?

      if @message.save
        respond_to do |format|
          format.turbo_stream {
            render "support/messages/create"
          }
          format.html { redirect_to request.referer || root_path, notice: "Message sent." }
        end
      else
        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "message_form",
              partial: "support/conversations/message_form",
              locals: {ticket: @ticket, message: @message}
            )
          }
          format.html { redirect_to request.referer || root_path, alert: "Message could not be sent." }
        end
      end
    end

    private

    def set_ticket
      @ticket = Support::Ticket.includes(:conversation).find(params[:ticket_id])
      @conversation = @ticket.conversation
    end

    def message_params
      params.require(:support_message).permit(:content)
    end
  end
end
