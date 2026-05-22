module Adminit
  class ApplicationController < SharedBaseController
    before_action :authorize_adminit_access
    verify_authorized

    private

    def authorize_adminit_access
      redirect_to "/" unless current_account&.adminit_access?
    end
  end
end
