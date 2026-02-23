module Support
  class TicketsController < DashboardController
    before_action :require_account
    verify_authorized

    before_action :set_ticket, only: %i[show edit update attach_files]
    before_action :ensure_frame_response, only: %i[new edit]

    # GET /support/tickets or /support/tickets.json
    def index
      authorize! :ticket, with: Support::TicketPolicy
      @tickets = Support::Ticket.where(created_id: current_account.id)
    end

    # GET /support/tickets/1 or /support/tickets/1.json
    def show
      authorize! @ticket
      @conversation = @ticket.conversation
      @messages = @conversation.messages.includes(:account).order(created_at: :asc)
    end

    # GET /support/tickets/new
    def new
      authorize! :ticket, with: Support::TicketPolicy
      @ticket = Support::Ticket.new
    end

    # GET /support/tickets/1/edit
    def edit
      authorize! @ticket, to: :update?
    end

    # POST /support/tickets or /support/tickets.json
    def create
      @ticket = Support::Ticket.new(ticket_params)
      @ticket.created_id = current_account.id
      authorize! @ticket
      respond_to do |format|
        if @ticket.save
          flash[:notice] = "Ticket was successfully created"
          format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, support_ticket_url(@ticket)) }
          format.html { redirect_to support_ticket_url(@ticket) }
          format.json { render :show, status: :created, location: @ticket }
        else
          format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", template: "support/tickets/new", locals: {ticket: @ticket}), status: :unprocessable_content }
          format.html { render :new, status: :unprocessable_content }
          format.json { render json: @ticket.errors, status: :unprocessable_content }
        end
      end
    end

    # PATCH/PUT /support/tickets/1 or /support/tickets/1.json
    def update
      authorize! @ticket
      respond_to do |format|
        if @ticket.update(ticket_params)
          format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, request.referer) }
          format.html { redirect_to support_ticket_url(@ticket), notice: "Ticket was successfully updated." }
          format.json { render :show, status: :ok, location: @ticket }
        else
          format.turbo_stream { render turbo_stream: turbo_stream.replace("ticket_form", partial: "support/tickets/form", locals: {ticket: @ticket}), status: :unprocessable_content }
          format.json { render json: @ticket.errors, status: :unprocessable_content }
        end
      end
    end

    # POST /support/tickets/1/attach_files
    def attach_files
      authorize! @ticket, to: :attach_files?
      if params[:support_ticket] && params[:support_ticket][:attachments]
        @ticket.attachments.attach(params[:support_ticket][:attachments])
        if @ticket.save
          flash[:notice] = "Files were successfully attached"
        else
          flash[:alert] = @ticket.errors.full_messages.join(", ")
        end
      else
        flash[:alert] = "No files selected"
      end
      redirect_to support_ticket_path(@ticket)
    end

    private

    def set_ticket
      @ticket = Support::Ticket.find(params[:id])
    end

    def ticket_params
      params.require(:support_ticket).permit(:title, :description, :category, attachments: [])
    end
  end
end
