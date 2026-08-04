module Adminit::DashboardHelper
  CHART_STATUS_COLORS = {
    open: :info,
    in_progress: :primary,
    pending: :warning,
    finished: :success,
    closed: :danger,
    draft: :warning,
    scheduled: :info,
    published: :success
  }.freeze

  CHART_HEIGHT = 280

  WIDGET_HEIGHT_SMALL = "max-h-96"
  WIDGET_HEIGHT_EXPANDED = "max-h-[40rem]"

  def auto_refresh_data(widget)
    return {} unless widget.refresh_interval

    {
      controller: "auto-refresh",
      auto_refresh_interval_value: widget.refresh_interval
    }
  end

  def chart_data(options = {}, height: CHART_HEIGHT)
    {
      controller: "chart",
      chart_options_value: options,
      chart_height_value: height
    }
  end
end
