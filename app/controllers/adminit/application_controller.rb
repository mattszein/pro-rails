module Adminit
  class ApplicationController < ActionController::Base
    default_form_builder CustomFormBuilder
    include LocaleMessages
    include ActionPolicyHandler

    before_action :authorize_adminit_access

    def index
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
      redirect_to "/" unless current_account&.adminit_access?
    end
  end
end
