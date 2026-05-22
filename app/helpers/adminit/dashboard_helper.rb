module Adminit::DashboardHelper
  def auto_refresh_data(widget)
    return {} unless widget.refresh_interval

    {
      controller: "auto-refresh",
      auto_refresh_interval_value: widget.refresh_interval
    }
  end
end
