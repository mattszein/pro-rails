class Adminit::TicketsController < Adminit::ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy take]

  # GET /tickets or /tickets.json
  def index
    authorize!
    @tickets = Ticket.all
  end

  # GET /tickets/1 or /tickets/1.json
  def show
    authorize! @ticket
  end

  # GET /tickets/1/edit
  def edit
    authorize! @ticket
  end

  # PATCH/PUT /tickets/1 or /tickets/1.json
  def update
    authorize! @ticket
    respond_to do |format|
      if @ticket.update(ticket_params)
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, request.referer) }
        format.html { redirect_to adminit_ticket_url(@ticket), notice: "Ticket was successfully updated." }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("ticket_form", partial: "adminit/tickets/form", locals: {ticket: @ticket}), status: :unprocessable_entity }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tickets/1 or /tickets/1.json
  def destroy
    authorize! @ticket
    @ticket.destroy!

    respond_to do |format|
      format.html { redirect_to adminit_tickets_url, notice: "Ticket was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /tickets/1/take
  def take
    authorize! @ticket, to: :take?
    respond_to do |format|
      if @ticket.open? && @ticket.update(assigned: current_account, status: :in_progress)
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, adminit_tickets_path) }
        format.html { redirect_to adminit_tickets_url, notice: "Ticket was successfully assigned to you." }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@ticket, "admin"), partial: "adminit/tickets/ticket_table", locals: {ticket: @ticket}), status: :unprocessable_entity }
        format.html { redirect_to adminit_tickets_url, alert: "Unable to take this ticket." }
        format.json { render json: {error: "Unable to take this ticket"}, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def ticket_params
    params.require(:ticket).permit(:title, :description, :priority, :status, :created_id, :assigned_id)
  end
end
