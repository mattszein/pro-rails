class BulkAnnouncementNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(announcement_id)
    announcement = Announcement.find_by(id: announcement_id)
    return unless announcement
    already_notified_ids = Noticed::Notification
      .where(recipient_type: "Account")
      .joins(:event)
      .where(noticed_events: {record: announcement})
      .select(:recipient_id)

    Account.verified.where.not(id: already_notified_ids).find_each do |account|
      AnnouncementNotifier.with(
        record: announcement,
        message: announcement.title
      ).deliver(account)
    end
  end
end
