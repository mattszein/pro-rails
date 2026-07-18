module Adminit
  class DashboardWidgetsController < ApplicationController
    before_action :require_account
    before_action :ensure_frame_response

    def show
      @widget = ::Dashboard::WidgetRegistry.find(params[:key])

      if @widget
        authorize! @widget.resource, with: @widget.policy_class.constantize
        return head :forbidden unless current_account.role&.dashboard_widgets&.include?(@widget)

        @component = @widget.component_class.constantize.new(account: current_account)
      else
        authorize! :dashboard_widget, with: Adminit::DashboardPolicy
        head :not_found
      end
    end
  end
end
