class Account < ApplicationRecord
  include Rodauth::Rails.model
  include Account::Notifiable

  enum :status, {unverified: 1, verified: 2, closed: 3}
  belongs_to :role, optional: true
  has_one :profile, dependent: :destroy

  after_create :create_default_profile

  scope :search_by_email, ->(query) { where("email ILIKE ?", "%#{query}%") }
  scope :not_in_role, ->(role) { where.not(role_id: role.id).or(where(role_id: nil)) }

  def adminit_access?
    role.present?
  end

  private

  def create_default_profile
    create_profile!
  end
end
