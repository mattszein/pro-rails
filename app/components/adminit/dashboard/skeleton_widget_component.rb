module Adminit
  module Dashboard
    class SkeletonWidgetComponent < ApplicationViewComponent
      def initialize(kind:)
        @kind = kind
      end
    end
  end
end
