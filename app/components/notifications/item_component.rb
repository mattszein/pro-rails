class Notifications::ItemComponent < ApplicationViewComponent
  option :notification

  def read_class
    @notification.read? ? "" : "unread"
  end

  def icon_class
    "bg-primary-100 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400"
  end
end
