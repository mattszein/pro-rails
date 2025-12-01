module Support
  class TicketsController < DashboardController
    before_action :set_ticket, only: %i[show edit update destroy]
    before_action :ensure_frame_response, only: %i[new edit]

    # GET /support/tickets or /support/tickets.json
    def index
      @tickets = Support::Ticket.where(created_id: current_account.id)
    end

    # GET /support/tickets/1 or /support/tickets/1.json
    def show
      @conversation = @ticket.conversation
      @messages = @conversation.messages.includes(:account).order(created_at: :asc)
    end

    # GET /support/tickets/new
    def new
      @ticket = Support::Ticket.new
    end

    # GET /support/tickets/1/edit
    def edit
    end

    # POST /support/tickets or /support/tickets.json
    def create
      @ticket = Support::Ticket.new(ticket_params)
      @ticket.created_id = current_account&.id
      respond_to do |format|
        if @ticket.save
          flash[:notice] = "Ticket was successfully created"
          format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, support_ticket_url(@ticket)) }
          format.html { redirect_to support_ticket_url(@ticket) }
          format.json { render :show, status: :created, location: @ticket }
        else
          format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", template: "support/tickets/new", locals: {ticket: @ticket}), status: :unprocessable_entity }
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @ticket.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /support/tickets/1 or /support/tickets/1.json
    def update
      respond_to do |format|
        if @ticket.update(ticket_params)
          format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, request.referer) }
          format.html { redirect_to support_ticket_url(@ticket), notice: "Ticket was successfully updated." }
          format.json { render :show, status: :ok, location: @ticket }
        else
          format.turbo_stream { render turbo_stream: turbo_stream.replace("ticket_form", partial: "support/tickets/form", locals: {ticket: @ticket}), status: :unprocessable_entity }
          format.json { render json: @ticket.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /support/tickets/1 or /support/tickets/1.json
    def destroy
      @ticket.destroy!

      respond_to do |format|
        format.html { redirect_to support_tickets_url, notice: "Ticket was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private

    def set_ticket
      @ticket = Support::Ticket.find(params[:id])
    end

    def ticket_params
      params.require(:support_ticket).permit(:title, :description, :category)
    end
  end
end
