class Notifications::ItemComponent < ApplicationViewComponent
  option :notification

  def read_class
    @notification.read? ? "" : "unread"
  end

  def icon_class
    "bg-primary-100 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400"
  end

  def time_ago
    return "Just now" if @notification.created_at > 1.minute.ago
    return "#{(Time.current - @notification.created_at).to_i / 60}m ago" if @notification.created_at > 1.hour.ago
    return "#{(Time.current - @notification.created_at).to_i / 3600}h ago" if @notification.created_at > 1.day.ago

    @notification.created_at.strftime("%b %-d")
  end
end
