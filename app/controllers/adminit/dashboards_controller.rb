class Adminit::DashboardsController < Adminit::ApplicationController
  before_action :require_account
  before_action :ensure_frame_response, only: :widget

  def index
    authorize! :dashboard, to: :show?, with: Adminit::DashboardPolicy
    @widgets = current_account.role&.dashboard_widgets || []
  end

  # Lazy widget endpoint: each widget turbo frame loads its body through here.
  def widget
    @widget = ::Dashboard::WidgetRegistry.find(params[:key])

    if @widget
      authorize! @widget.resource, with: @widget.policy_class.constantize
      return head :forbidden unless current_account.role&.dashboard_widgets&.include?(@widget)

      @component = @widget.component_class.constantize.new(account: current_account)
    else
      authorize! :dashboard_widget, to: :show?, with: Adminit::DashboardPolicy
      head :not_found
    end
  end
end
