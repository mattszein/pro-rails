class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  default_form_builder CustomFormBuilder

  include Pagy::Backend
  include ErrorResponseActions
  include ActionPolicyHandler
  include RecordNotFoundHandler
  include LocaleMessages

  def index
  end
end
