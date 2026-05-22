module Adminit
  class DashboardsController < ApplicationController
    before_action :require_account

    def index
      authorize! :dashboard, to: :show?, with: Adminit::DashboardPolicy
      @widgets = current_account.role&.dashboard_widgets || []
    end
  end
end
