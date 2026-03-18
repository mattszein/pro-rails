class DashboardController < SharedBaseController
  before_action :set_sidebar_open

  def index
    @current_account = current_account
  end

  private

  def set_sidebar_open
    value = cookies["sidebar"]
    @sidebar_open = !value.nil? && value == "1"
  end
end
