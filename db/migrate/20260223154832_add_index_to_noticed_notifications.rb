class AddIndexToNoticedNotifications < ActiveRecord::Migration[8.0]
  def change
    add_index :noticed_notifications, [:recipient_type, :recipient_id, :read_at],
      name: :index_noticed_notifications_on_recipient_and_read_at
  end
end
