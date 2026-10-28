module Support
  class TicketsController < DashboardController
    include Tableable

    before_action :require_account
    verify_authorized

    before_action :set_ticket, only: %i[show attach_files request_reopen resolve_with_ai request_human]
    before_action :ensure_frame_response, only: %i[new]

    def index
      authorize! :ticket, with: Support::TicketPolicy
      @columns = helpers.support_ticket_columns
      @pagy, @tickets = apply_table_params(
        Support::Ticket.where(created_id: current_account.id).prioritized,
        columns: @columns
      )
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

    # POST /support/tickets or /support/tickets.json
    def create
      @ticket = Support::Ticket.new(ticket_params)
      @ticket.created_id = current_account.id
      authorize! @ticket
      respond_to do |format|
        if Support::Tickets::Create.call(ticket: @ticket).success?
          flash[:notice] = I18n.t("support.tickets.created")
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

    # POST /support/tickets/1/attach_files
    def attach_files
      authorize! @ticket, to: :attach_files?
      if params[:support_ticket] && params[:support_ticket][:attachments]
        @ticket.attachments.attach(params[:support_ticket][:attachments])
        if @ticket.save
          flash[:notice] = I18n.t("support.tickets.files_attached")
        else
          flash[:alert] = @ticket.errors.full_messages.join(", ")
        end
      else
        flash[:alert] = I18n.t("support.tickets.no_files_selected")
      end
      redirect_to support_ticket_path(@ticket)
    end

    # POST /support/tickets/1/request_reopen
    def request_reopen
      authorize! @ticket
      result = Support::Tickets::RequestReopen.call(
        ticket: @ticket,
        account: current_account,
        body: params[:reason]
      )

      if result.success?
        redirect_to support_ticket_path(@ticket), notice: I18n.t("support.tickets.reopen_sent")
      else
        redirect_to support_ticket_path(@ticket), alert: result.error
      end
    end

    # POST /support/tickets/1/resolve_with_ai
    def resolve_with_ai
      authorize! @ticket
      result = Support::Tickets::ResolveWithAi.call(ticket: @ticket, account: current_account)

      if result.success?
        redirect_to support_ticket_path(@ticket), notice: I18n.t("support.tickets.resolved_with_ai")
      else
        redirect_to support_ticket_path(@ticket), alert: result.error
      end
    end

    # POST /support/tickets/1/request_human
    def request_human
      authorize! @ticket
      result = Support::Tickets::RequestHuman.call(ticket: @ticket, account: current_account)

      if result.success?
        redirect_to support_ticket_path(@ticket), notice: I18n.t("support.tickets.human_requested")
      else
        redirect_to support_ticket_path(@ticket), alert: result.error
      end
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
