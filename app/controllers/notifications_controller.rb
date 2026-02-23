class NotificationsController < DashboardController
  before_action :require_account
  verify_authorized

  def index
    authorize! :notification
    @notifications = current_account.notifications_feed
    @unread_count = current_account.unread_notifications_count
  end

  def user
    authorize! :notification
    @notifications = current_account.unread_notifications(limit: 10)
    @unread_count = current_account.unread_notifications_count
  end

  def mark_all_read
    authorize! :notification
    current_account.notifications.unread.update_all(read_at: Time.current)
    head :ok
  end

  def mark_as_read
    notification = Noticed::Notification.find(params[:id])
    authorize! notification, with: NotificationPolicy
    notification.mark_as_read!
    head :ok
  end
end
