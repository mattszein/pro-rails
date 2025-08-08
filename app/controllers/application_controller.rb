class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  default_form_builder CustomFormBuilder

  include ErrorResponseActions
  before_action :set_sidebar_open

  def index
  end

  private

  def set_sidebar_open
    value = cookies["sidebar"]
    @sidebar_open = !value.nil? && value == "1"
  end

  def current_account
    rodauth.rails_account
  end
  helper_method :current_account # skip if inheriting from ActionController::API
end
