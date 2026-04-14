# frozen_string_literal: true

class Avatar < ApplicationRecord
  class InvalidTransition < StandardError; end

  # Associations
  belongs_to :profile

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
    attachable.variant :medium, resize_to_limit: [300, 300]
  end

  # Enums
  enum :kind, {manual: 0, generated: 1}, prefix: false
  enum :status, {draft: 0, generating: 1, completed: 2, failed: 3}, prefix: false

  # Validations
  validates :profile_id, presence: true
  validates :kind, presence: true
  validates :status, presence: true
  validate :generation_method_present, if: :generated?
  validates :dna_version, presence: true, if: :generated?
  validate :image_attached_when_completed

  # Scopes
  scope :visible, -> { where(visible: true) }
  scope :for_gallery, -> { where(status: :completed).order(created_at: :desc) }
  scope :generated_today, -> {
    where(kind: :generated)
      .where(status: [:generating, :completed])
      .where(created_at: Time.current.beginning_of_day..)
  }

  # Transition methods — pure database operations, no side effects
  def start_generating!
    raise InvalidTransition, "can only start generating from draft or failed" unless draft? || failed?
    raise InvalidTransition, "only generated avatars can be generated" unless generated?
    update!(status: :generating)
  end

  def complete!
    raise InvalidTransition, "can only complete from generating" unless generating?
    update!(status: :completed)
  end

  def fail!
    raise InvalidTransition, "can only fail from generating" unless generating?
    update!(status: :failed)
  end

  # Query methods
  def editable?
    draft? && generated?
  end

  def selectable?
    completed?
  end

  def evolvable?
    completed? && generated?
  end

  private

  def generation_method_present
    errors.add(:method, :blank) if read_attribute(:method).nil?
  end

  def image_attached_when_completed
    return unless completed?
    return if image.attached?

    errors.add(:image, :blank)
  end
end
