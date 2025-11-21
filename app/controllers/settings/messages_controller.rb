# app/controllers/messages_controller.rb
class Settings::MessagesController < ApplicationController
  before_action :set_ticket

  def create
    @message = @conversation.messages.build(message_params)
    @message.account = current_account

    authorize! @message, to: :create?

    if @message.save
      respond_to do |format|
        format.turbo_stream {
          render "messages/create"
        }
        format.html { redirect_to @ticket, notice: "Message sent." }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "messages/create",
            locals: {ticket: @ticket, message: @message}
          )
        }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    @message = @conversation.messages.find(params[:id])
    authorize! @message, to: :update?

    if @message.update(message_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @ticket, notice: "Message updated." }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @message = @conversation.messages.find(params[:id])
    authorize! @message, to: :destroy?

    @message.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @ticket, notice: "Message deleted." }
    end
  end

  private

  def set_ticket
    @ticket = Ticket.includes(:conversation).find(params[:ticket_id])
    @conversation = @ticket.conversation
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
