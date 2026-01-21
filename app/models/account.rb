class Account < ApplicationRecord
  include Rodauth::Rails.model
  enum :status, {unverified: 1, verified: 2, closed: 3}
  belongs_to :role, optional: true
  has_many :notifications, as: :recipient, class_name: "Noticed::Notification"

  def adminit_access?
    role.present?
  end
end
