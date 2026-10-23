class Adminit::AiPlaybooksController < Adminit::ApplicationController
  before_action :set_playbook, only: %i[edit update destroy toggle move_up move_down]
  verify_authorized

  def index
    authorize! Support::AiPlaybook, with: Adminit::AiPlaybookPolicy
    @playbooks = Support::AiPlaybook.listed.includes(:audience).to_a
  end

  def new
    authorize! Support::AiPlaybook, with: Adminit::AiPlaybookPolicy
    @playbook = Support::AiPlaybook.new(capabilities: SupportAi::Capabilities::Registry.defaults.map { |c| c.key.to_s })
  end

  def edit
  end

  def create
    authorize! Support::AiPlaybook, with: Adminit::AiPlaybookPolicy
    @playbook = Support::AiPlaybook.new(playbook_params)
    if @playbook.save
      respond_success(resource_message(:created, @playbook))
    else
      respond_form_error(:new)
    end
  end

  def update
    if @playbook.update(playbook_params)
      respond_success(resource_message(:updated, @playbook))
    else
      respond_form_error(:edit)
    end
  end

  # The model aborts the destroy of the default playbook; surface its message.
  def destroy
    if @playbook.destroy
      redirect_to adminit_ai_playbooks_path, notice: resource_message(:deleted, @playbook)
    else
      redirect_to adminit_ai_playbooks_path, alert: @playbook.errors.full_messages.to_sentence
    end
  end

  # Decision: the default playbook CAN be disabled. A disabled default means
  # tickets that match no other playbook get no AI at all.
  def toggle
    @playbook.update!(enabled: !@playbook.enabled?)
    redirect_to adminit_ai_playbooks_path,
      notice: t(@playbook.enabled? ? "adminit.ai_playbooks.toggled_on" : "adminit.ai_playbooks.toggled_off")
  end

  def move_up = move(:up)

  def move_down = move(:down)

  private

  def move(direction)
    if @playbook.move!(direction)
      redirect_to adminit_ai_playbooks_path, notice: t("adminit.ai_playbooks.moved")
    else
      redirect_to adminit_ai_playbooks_path, alert: t("adminit.ai_playbooks.cannot_move")
    end
  end

  def set_playbook
    @playbook = Support::AiPlaybook.find(params[:id])
    authorize! @playbook, with: Adminit::AiPlaybookPolicy
  end

  PERMITTED = %i[name enabled mode instructions max_ai_turns idle_reminder_after_hours idle_handoff_after_hours].freeze
  CONDITIONS = %i[min_priority max_priority audience_id].freeze

  # The default playbook's conditions are locked: they are never permitted,
  # whatever the request carries.
  def playbook_params
    permitted = params.require(:support_ai_playbook).permit(*PERMITTED, *CONDITIONS, capabilities: [], category_keys: [])
    return permitted unless @playbook&.is_default?

    permitted.except(*CONDITIONS, :category_keys)
  end

  # New/edit render in a modal frame: on success the frame redirects to the
  # index, on failure the form is re-rendered in place.
  def respond_success(message)
    respond_to do |format|
      format.html { redirect_to adminit_ai_playbooks_path, notice: message }
      format.turbo_stream do
        flash[:notice] = message
        render turbo_stream: turbo_stream.action(:redirect, adminit_ai_playbooks_path)
      end
    end
  end

  def respond_form_error(action)
    respond_to do |format|
      format.html { render action, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "ai_playbook_form",
          partial: "adminit/ai_playbooks/form",
          locals: {playbook: @playbook}
        ), status: :unprocessable_content
      end
    end
  end
end
