module Announcements
  class Unschedule
    include Interactor

    delegate :announcement, to: :context

    def call
      announcement.unschedule!
    rescue Announcement::InvalidTransition, ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end
  end
end
