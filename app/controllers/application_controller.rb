class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  default_form_builder CustomFormBuilder

  include ErrorResponseActions
  include LocaleMessages
  include Localizable

  def index
  end
end
