module Announcements
  class Publish
    include Interactor

    delegate :announcement, to: :context

    def call
      announcement.publish!
      BulkAnnouncementNotificationJob.perform_later(announcement.id)
    rescue Announcement::InvalidTransition, ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end
  end
end
