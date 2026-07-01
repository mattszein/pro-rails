module Adminit
  class BreadcrumbComponent < ApplicationViewComponent
    Crumb = Data.define(:label, :path, :icon) do
      def initialize(label:, path: nil, icon: nil) = super
    end

    option :trail, default: -> { [] } # Array<Crumb>

    # A lone "Dash" crumb means we're on the dashboard home → render nothing.
    def render?
      trail.length > 1
    end

    def last?(index) = index == trail.length - 1
  end
end
