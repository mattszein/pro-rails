module Announcements
  class Schedule
    include Interactor

    delegate :announcement, to: :context

    def call
      announcement.schedule!
      enqueue_publish_job
    rescue Announcement::InvalidTransition, ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end

    private

    def enqueue_publish_job
      PublishAnnouncementJob
        .set(wait_until: announcement.scheduled_at)
        .perform_later(announcement.id, announcement.scheduled_at.to_i)
    end
  end
end
