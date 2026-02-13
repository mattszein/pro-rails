  class Notifications::ItemComponent < ApplicationViewComponent
    option :notification

    def read_class
      @notification.read? ? "" : "unread"
    end

    def icon_class
        "bg-primary-100 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400"
    end

    def icon_svg
        '<path stroke-linecap="round" stroke-linejoin="round" d="M10.34 15.84c-.688-.06-1.386-.09-2.09-.09H7.5a4.5 4.5 0 1 1 0-9h.75c.704 0 1.402-.03 2.09-.09m0 9.18c.253.962.584 1.892.985 2.783.247.55.06 1.21-.463 1.511l-.657.38c-.551.318-1.26.117-1.527-.461a20.845 20.845 0 0 1-1.44-4.282m3.102.069a18.03 18.03 0 0 1-.59-4.59c0-1.586.205-3.124.59-4.59m0 9.18a23.848 23.848 0 0 1 8.835 2.535M10.34 6.66a23.847 23.847 0 0 0 8.835-2.535m0 0A23.74 23.74 0 0 0 18.795 3m.38 1.125a23.91 23.91 0 0 1 1.014 5.395m-1.014 8.855c-.118.38-.245.754-.38 1.125m.38-1.125a23.91 23.91 0 0 0 1.014-5.395m0-3.46c.495.413.811 1.035.811 1.73 0 .695-.316 1.317-.811 1.73m0-3.46a24.347 24.347 0 0 1 0 3.46" />'
    end

    def time_ago
      return "Just now" if @notification.created_at > 1.minute.ago
      return "#{(Time.current - @notification.created_at).to_i / 60}m ago" if @notification.created_at > 1.hour.ago
      return "#{(Time.current - @notification.created_at).to_i / 3600}h ago" if @notification.created_at > 1.day.ago
      
      @notification.created_at.strftime("%b %-d")
    end
  end
