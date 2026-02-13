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
      AnnouncementNotifier.with(record: announcement, message: announcement.title).deliver(Account.all)
    end
  end
end
