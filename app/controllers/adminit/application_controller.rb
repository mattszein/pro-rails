module Adminit
  class ApplicationController < ActionController::Base
    default_form_builder CustomFormBuilder
    before_action :authorize_adminit_access

    rescue_from ActionPolicy::Unauthorized do |ex|
      msg = I18n.t("adminit.authorization.unauthorized")
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.update("flashes_id", partial: "shared/flash", locals: {msg: msg})
        }
        format.html { redirect_to "/", flash: {alert: msg} }
      end
    end

    private

    def current_account
      rodauth.rails_account
    end

    alias_method :current_user, :current_account
    helper_method :current_account # skip if inheriting from ActionController::API

    def ensure_frame_response
      redirect_to root_path unless turbo_frame_request?
    end

    def authorize_adminit_access
      redirect_to "/", flash: {alert: "You are not worthy!"} unless current_account&.adminit_access?
    end
  end
end
