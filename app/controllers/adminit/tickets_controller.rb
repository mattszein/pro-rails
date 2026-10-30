class Adminit::TicketsController < Adminit::ApplicationController
  include Tableable
  include TransitionErrors

  before_action :set_ticket, only: %i[edit update destroy take leave finish reopen accept_reopen new_reject_reopen reject_reopen]
  before_action :ensure_frame_response, only: %i[edit new_reject_reopen]

  def index
    authorize! Support::Ticket, with: Adminit::TicketPolicy
    @columns = helpers.ticket_columns
    @pagy, @tickets = apply_table_params(
      Support::Ticket.includes(:created, :assigned).prioritized,
      columns: @columns
    )
  end

  # GET /tickets/1 or /tickets/1.json
  def show
    # The partial is also broadcast from a job (no controller), so it reads plain associations from
    # `ticket`; preloading here is what keeps this page free of N+1 queries.
    @ticket = Support::Ticket.includes(notes: :account, conversation: {messages: :account}).find(params[:id])
    authorize! @ticket, with: Adminit::TicketPolicy
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
    @ticket.take!(by: current_account)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_ticket_path(@ticket)) }
      format.html { redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.assigned") }
      format.json { render :show, status: :ok, location: @ticket }
    end
  end

  # POST /tickets/1/leave
  def leave
    authorize! @ticket, to: :leave?, with: Adminit::TicketPolicy
    @ticket.unassign!(by: current_account)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_tickets_path) }
      format.html { redirect_to adminit_tickets_url, notice: I18n.t("adminit.tickets.left") }
      format.json { render :show, status: :ok, location: @ticket }
    end
  end

  # POST /tickets/1/finish
  def finish
    authorize! @ticket, with: Adminit::TicketPolicy
    @ticket.finish!(by: current_account)
    redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.finished")
  end

  # POST /tickets/1/reopen
  def reopen
    authorize! @ticket, with: Adminit::TicketPolicy
    @ticket.reopen!(by: current_account)
    redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.reopened")
  end

  # POST /tickets/1/accept_reopen
  def accept_reopen
    authorize! @ticket, with: Adminit::TicketPolicy
    @ticket.accept_reopen!(by: current_account)
    redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.reopen_accepted")
  end

  # GET /tickets/1/reject_reopen
  def new_reject_reopen
    authorize! @ticket, to: :reject_reopen?, with: Adminit::TicketPolicy
  end

  # POST /tickets/1/reject_reopen
  def reject_reopen
    authorize! @ticket, with: Adminit::TicketPolicy
    @ticket.reject_reopen!(by: current_account, reason: params[:reason])

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_ticket_path(@ticket)) }
      format.html { redirect_to adminit_ticket_path(@ticket), notice: I18n.t("adminit.tickets.reopen_rejected") }
    end
  end

  private

  def set_ticket
    @ticket = Support::Ticket.find(params[:id])
  end

  def transition_error_path
    @ticket ? adminit_ticket_path(@ticket) : adminit_tickets_path
  end

  def ticket_params
    params.require(:support_ticket).permit(:title, :description, :priority, :category)
  end
end
