class Announcement < ApplicationRecord
  belongs_to :author, class_name: "Account"

  enum :status, {
    draft: 0,
    scheduled: 1,
    published: 2,
  }, default: :draft, validate: {allow_nil: false}

  validates :title, presence: true
  validates :body, presence: true
  validates :scheduled_at, presence: true, if: :scheduled?
  validate :scheduled_at_cannot_be_in_the_past
  validate :cannot_change_scheduled_at_if_scheduled, on: :update
  validate :cannot_update_if_published, on: :update

  scope :ready_to_publish, -> { where(status: :scheduled).where("scheduled_at <= ?", Time.current) }
  default_scope { order(created_at: :desc) }

  def destroyable?
    draft?
  end

  def editable?
    !published?
  end

  def can_change_scheduled_at?
    !scheduled? && !published?
  end

  def can_transition_to_draft?
    !published?
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

  def scheduled_at_cannot_be_in_the_past
    if scheduled_at.present? && scheduled_at < Time.current
      errors.add(:scheduled_at, "cannot be in the past")
    end
  end

  def cannot_change_scheduled_at_if_scheduled
    if scheduled? && scheduled_at_changed?
      errors.add(:scheduled_at, "cannot be changed for scheduled announcements")
    end
  end

  def cannot_update_if_published
    if status_was == "published"
      errors.add(:base, "cannot be updated once published")
    end
  end
end
