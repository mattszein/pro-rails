class Announcement < ApplicationRecord
  class InvalidTransition < StandardError; end
  SCHEDULE_TOLERANCE = 3.minutes
  belongs_to :author, class_name: "Account"

  enum :status, {
    draft: 0,
    scheduled: 1,
    published: 2
  }, default: :draft, validate: {allow_nil: false}

  validates :title, presence: true
  validates :body, presence: true
  validates :scheduled_at, presence: true, if: :scheduled?

  validate :scheduled_at_immutable_when_scheduled, on: :update
  validate :cannot_update_when_published, on: :update

  before_destroy :ensure_destroyable

  scope :ready_to_publish, -> { where(status: :scheduled).where("scheduled_at <= ?", Time.current) }
  scope :overdue, -> { scheduled.where("scheduled_at <= ?", 5.minutes.ago) }
  scope :ordered, -> { order(created_at: :desc) }

  # query methods for states
  def schedulable?
    draft? && scheduled_at.present?
  end

  def scheduled_at_editable?
    draft?
  end

  def destroyable?
    draft?
  end

  def editable?
    !published?
  end

  # Transitions states
  def schedule!
    raise InvalidTransition, "Cannot schedule a published announcement" if published?
    raise InvalidTransition, "Already scheduled" if scheduled?
    raise InvalidTransition, "Scheduled time is required" if scheduled_at.blank?
    raise InvalidTransition, "Scheduled time must be in the future" if scheduled_at < SCHEDULE_TOLERANCE.ago

    update!(status: :scheduled)
  end

  def unschedule!
    raise InvalidTransition, "Can only unschedule scheduled announcements" unless scheduled?
    update!(status: :draft)
  end

  def publish!
    raise InvalidTransition, "Already published" if published?
    raise InvalidTransition, "Must be scheduled first" unless scheduled?

    update!(status: :published, published_at: Time.current)
  end

  def scheduled_at=(value)
    if value.is_a?(String)
      super(DateTime.strptime(value, "%m/%d/%Y %I:%M %p"))
    else
      super
    end
  rescue ArgumentError
    super(nil)
  end

  private

  def scheduled_at_immutable_when_scheduled
    if scheduled? && scheduled_at_changed?
      errors.add(:scheduled_at, "cannot be changed when scheduled. Unschedule first.")
    end
  end

  def cannot_update_when_published
    if status_was == "published"
      errors.add(:base, "Cannot update a published announcement")
    end
  end

  def ensure_destroyable
    unless draft?
      errors.add(:base, "Only draft announcements can be deleted")
      throw(:abort)
    end
  end
end
