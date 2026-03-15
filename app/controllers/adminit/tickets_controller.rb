class Adminit::TicketsController < Adminit::ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy take leave finish reopen accept_reopen new_reject_reopen reject_reopen]
  before_action :ensure_frame_response, only: %i[edit new_reject_reopen]

  # GET /tickets or /tickets.json
  def index
    authorize! Support::Ticket, with: Adminit::TicketPolicy
    @tickets = Support::Ticket.all
  end

  # GET /tickets/1 or /tickets/1.json
  def show
    authorize! @ticket, with: Adminit::TicketPolicy
    @conversation = @ticket.conversation
    @messages = @conversation.messages.includes(:account).order(created_at: :asc)
    @notes = @ticket.notes.includes(:account).order(created_at: :desc)
  end

  # GET /tickets/1/edit
  def edit
    authorize! @ticket, with: Adminit::TicketPolicy
  end

  # PATCH/PUT /tickets/1 or /tickets/1.json
  def update
    authorize! @ticket, with: Adminit::TicketPolicy
    respond_to do |format|
      if @ticket.update(ticket_params)
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, request.referer) }
        format.html { redirect_to adminit_ticket_url(@ticket), notice: I18n.t("adminit.tickets.updated") }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("ticket_form", partial: "adminit/tickets/form", locals: {ticket: @ticket}), status: :unprocessable_content }
        format.json { render json: @ticket.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /tickets/1 or /tickets/1.json
  def destroy
    authorize! @ticket, with: Adminit::TicketPolicy
    @ticket.destroy!

    respond_to do |format|
      format.html { redirect_to adminit_tickets_url, notice: I18n.t("adminit.tickets.destroyed") }
      format.json { head :no_content }
    end
  end

  # POST /tickets/1/take
  def take
    authorize! @ticket, to: :take?, with: Adminit::TicketPolicy
    result = Adminit::Tickets::Take.call(ticket: @ticket, account: current_account)

    respond_to do |format|
      if result.success?
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_ticket_path(@ticket)) }
        format.html { redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.assigned") }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@ticket, "admin"), partial: "adminit/tickets/ticket_row", locals: {ticket: @ticket}), status: :unprocessable_content }
        format.html { redirect_to adminit_tickets_url, alert: result.error }
        format.json { render json: {error: result.error}, status: :unprocessable_content }
      end
    end
  end

  # POST /tickets/1/leave
  def leave
    authorize! @ticket, to: :leave?, with: Adminit::TicketPolicy
    result = Adminit::Tickets::Leave.call(ticket: @ticket, account: current_account)

    respond_to do |format|
      if result.success?
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_tickets_path) }
        format.html { redirect_to adminit_tickets_url, notice: I18n.t("adminit.tickets.left") }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@ticket, "admin"), partial: "adminit/tickets/ticket_row", locals: {ticket: @ticket}), status: :unprocessable_content }
        format.html { redirect_to adminit_tickets_url, alert: result.error }
        format.json { render json: {error: result.error}, status: :unprocessable_content }
      end
    end
  end

  # POST /tickets/1/finish
  def finish
    authorize! @ticket, with: Adminit::TicketPolicy
    result = Adminit::Tickets::Finish.call(ticket: @ticket, account: current_account)

    respond_to do |format|
      if result.success?
        format.html { redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.finished") }
      else
        format.html { redirect_to adminit_ticket_path(@ticket), alert: result.error }
      end
    end
  end

  # POST /tickets/1/reopen
  def reopen
    authorize! @ticket, with: Adminit::TicketPolicy
    result = Adminit::Tickets::Reopen.call(ticket: @ticket, account: current_account)

    respond_to do |format|
      if result.success?
        format.html { redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.reopened") }
      else
        format.html { redirect_to adminit_ticket_path(@ticket), alert: result.error }
      end
    end
  end

  # POST /tickets/1/accept_reopen
  def accept_reopen
    authorize! @ticket, with: Adminit::TicketPolicy
    result = Adminit::Tickets::AcceptReopen.call(ticket: @ticket, account: current_account)

    respond_to do |format|
      if result.success?
        format.html { redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.reopen_accepted") }
      else
        format.html { redirect_to adminit_ticket_path(@ticket), alert: result.error }
      end
    end
  end

  # GET /tickets/1/reject_reopen
  def new_reject_reopen
    authorize! @ticket, to: :reject_reopen?, with: Adminit::TicketPolicy
  end

  # POST /tickets/1/reject_reopen
  def reject_reopen
    authorize! @ticket, with: Adminit::TicketPolicy
    result = Adminit::Tickets::RejectReopen.call(ticket: @ticket, account: current_account, body: params[:reason])

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_ticket_path(@ticket)) }
      if result.success?
        format.html { redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.reopen_rejected") }
      else
        format.html { redirect_to adminit_ticket_path(@ticket), alert: result.error }
      end
    end
  end

  private

  def set_ticket
    @ticket = Support::Ticket.find(params[:id])
  end

  def ticket_params
    params.require(:support_ticket).permit(:title, :description, :priority, :status, :category, :created_id, :assigned_id)
  end
end
