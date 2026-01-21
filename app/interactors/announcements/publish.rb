module Announcements
  class Publish
    include Interactor

    delegate :announcement, to: :context

    def call
      ActiveRecord::Base.transaction do
        announcement.publish!
        deliver_notifications
      end
    rescue Announcement::InvalidTransition, ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end

    private

    def deliver_notifications
      # TODO: Implement notification delivery with Noticed gem
      # AnnouncementNotifier.with(record: announcement).deliver(Account.verified)
      Rails.logger.info "Announcement ##{announcement.id} published."
      AnnouncementNotifier.with(record: announcement, message: announcement.title).deliver(Account.all)
    end
  end
end
