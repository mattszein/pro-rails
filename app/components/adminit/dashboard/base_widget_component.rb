module Adminit
  module Dashboard
    class BaseWidgetComponent < ApplicationViewComponent
      def initialize(title:, view_all_path: nil, view_all_label: nil)
        @title = title
        @view_all_path = view_all_path
        @view_all_label = view_all_label
      end
    end
  end
end
