class SharedBaseController < ApplicationController
  private

  def current_account
    rodauth.rails_account
  end

  alias_method :current_user, :current_account
  helper_method :current_account

  def require_account
    rodauth.require_account
  end

  def ensure_frame_response
    redirect_to root_path unless turbo_frame_request?
  end
end
