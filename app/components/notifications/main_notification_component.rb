class Notifications::MainNotificationComponent < ApplicationViewComponent
  option :unread_count, default: -> { 0 }
  option :notifications, default: -> { [] }
  option :current_account_id
end
