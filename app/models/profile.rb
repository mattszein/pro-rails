# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :account
  belongs_to :avatar, optional: true
  has_many :avatars, dependent: :destroy

  before_destroy :nullify_active_avatar, prepend: true

  validates :bio, length: {maximum: 500}
  validates :username,
    uniqueness: {allow_blank: true},
    format: {
      with: /\A[a-zA-Z0-9_]+\z/,
      message: :invalid_format,
      allow_blank: true
    }

  private

  def nullify_active_avatar
    update_column(:avatar_id, nil)
  end
end
