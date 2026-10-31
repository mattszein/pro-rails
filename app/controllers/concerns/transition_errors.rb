# Renders expected domain failures (invalid state transitions, record validation) as an alert
# instead of a 500. The including controller overrides `transition_error_path` with the page the
# user should land on; anything that is not a DomainError/RecordInvalid keeps raising.
module TransitionErrors
  extend ActiveSupport::Concern

  included do
    rescue_from DomainError, ActiveRecord::RecordInvalid, with: :handle_transition_error
  end

  private

  def handle_transition_error(error)
    message = error.is_a?(ActiveRecord::RecordInvalid) ? error.record.errors.full_messages.to_sentence : error.message
    render_transition_error(message)
  end

  def render_transition_error(message)
    respond_to do |format|
      format.html { redirect_back_or_to transition_error_path, alert: message }
      format.turbo_stream do
        flash[:alert] = message
        render turbo_stream: turbo_stream.action(:redirect, transition_error_path)
      end
      format.json { render json: {error: message}, status: :unprocessable_content }
    end
  end

  def transition_error_path
    root_path
  end
end
