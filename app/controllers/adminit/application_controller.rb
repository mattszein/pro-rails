module Adminit
  class ApplicationController < ActionController::Base
    default_form_builder CustomFormBuilder

    private

    def current_account
      rodauth.rails_account
    end

    helper_method :current_account # skip if inheriting from ActionController::API
    def ensure_frame_response
      redirect_to root_path unless turbo_frame_request?
    end
  end
end
