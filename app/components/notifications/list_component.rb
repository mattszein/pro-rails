class Notifications::ListComponent < ApplicationViewComponent
  option :notifications, default: -> { [] }

  def empty?
    notifications.empty?
  end
end
