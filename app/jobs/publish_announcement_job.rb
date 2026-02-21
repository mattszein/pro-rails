class PublishAnnouncementJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(announcement_id, expected_scheduled_at)
    announcement = Announcement.find_by(id: announcement_id)
    return unless announcement

    # Job is stale (announcement was rescheduled or in other state)
    return if announcement.scheduled_at.to_i != expected_scheduled_at

    result = Announcements::Publish.call(announcement: announcement)
    if result.failure?
      Rails.logger.error("PublishJob Failed for Announcement #{announcement_id}: #{result.error}")
    else
      Rails.logger.info("Published Announcement #{announcement_id} successfully")
    end
  end
end
