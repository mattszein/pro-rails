module Adminit
  module Dashboard
    # Wraps the `chart` Stimulus controller (ApexCharts) so widgets render a
    # chart with a plain component call instead of a hand-rolled tag.div.
    class ChartComponent < ApplicationViewComponent
      option :options
      option :height, default: -> { Adminit::DashboardHelper::CHART_HEIGHT }
    end
  end
end
