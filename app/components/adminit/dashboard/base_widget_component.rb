module Adminit
  module Dashboard
    class BaseWidgetComponent < ApplicationViewComponent
      option :view_all_path, default: -> {}
      option :view_all_label, default: -> {}
    end
  end
end
