module Adminit
  module Dashboard
    class BaseWidgetComponent < ApplicationViewComponent
      option :empty, default: -> { false }
    end
  end
end
