class DashboardController < ApplicationController
  allow_browser versions: :modern
  default_form_builder CustomFormBuilder

  include ErrorResponseActions
  include ActionPolicyHandler
  include RecordNotFoundHandler

  before_action :set_sidebar_open

  def index
    @current_account = current_account
  end

  private

  def set_sidebar_open
    value = cookies["sidebar"]
    @sidebar_open = !value.nil? && value == "1"
  end

  def current_account
    rodauth.rails_account
  end

  alias_method :current_user, :current_account
  helper_method :current_account # skip if inheriting from ActionController::API

  def require_account
    rodauth.require_account
  end

  def ensure_frame_response
    redirect_to root_path unless turbo_frame_request?
  end
end
