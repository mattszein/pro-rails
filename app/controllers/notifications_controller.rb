class NotificationsController < DashboardController
  def index
    @notifications = current_account.notifications.includes(event: :record).order(created_at: :desc)
    @unread_count = @notifications.unread.count
  end

  def user
    @notifications = current_account.notifications.includes(event: :record).unread.order(created_at: :desc).limit(10)
    @unread_count = current_account.notifications.unread.count
  end

  def mark_all_read
    current_account.notifications.unread.update_all(read_at: Time.current)
    head :ok
  end

  def mark_as_read
    notification = current_account.notifications.find(params[:id])
    notification.mark_as_read!
    head :ok
  end

end
