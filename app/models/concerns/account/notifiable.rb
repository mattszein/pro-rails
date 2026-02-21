module Account::Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :recipient, class_name: "Noticed::Notification"
  end

  def notifications_feed
    notifications_base_scope
  end

  def unread_notifications(limit: nil)
    scope = notifications_base_scope.unread
    limit ? scope.limit(limit) : scope
  end

  def unread_notifications_count
    notifications.unread.count
  end

  private

  def notifications_base_scope
    notifications.includes(event: :record).order(created_at: :desc)
  end
end
