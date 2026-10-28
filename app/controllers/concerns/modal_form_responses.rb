# Responses for create/update forms rendered in a modal frame: success redirects the page,
# failure re-renders the form in place. The including controller defines `modal_form_locals`
# (locals for its `_form` partial); the frame id is "<singular controller name>_form".
module ModalFormResponses
  extend ActiveSupport::Concern

  private

  def respond_success(message, path)
    respond_to do |format|
      format.html { redirect_to path, notice: message }
      format.turbo_stream do
        flash[:notice] = message
        render turbo_stream: turbo_stream.action(:redirect, path)
      end
    end
  end

  def respond_form_error(action)
    respond_to do |format|
      format.html { render action, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "#{controller_name.singularize}_form",
          partial: "#{controller_path}/form",
          locals: modal_form_locals
        ), status: :unprocessable_content
      end
    end
  end
end
