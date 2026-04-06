class Profile < ApplicationRecord
  belongs_to :account

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
    attachable.variant :medium, resize_to_limit: [300, 300]
  end

  validates :bio, length: {maximum: 500}
  validates :username,
    uniqueness: {allow_blank: true},
    format: {
      with: /\A[a-zA-Z0-9_]+\z/,
      message: :invalid_format,
      allow_blank: true
    }
  validate :acceptable_avatar

  private

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.blob.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:avatar, :invalid_content_type)
    end

    if avatar.blob.byte_size > 10.megabytes
      errors.add(:avatar, :file_too_large)
    end
  end
end
