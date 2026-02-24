class Account < ApplicationRecord
  include Rodauth::Rails.model
  include Account::Notifiable

  enum :status, {unverified: 1, verified: 2, closed: 3}
  belongs_to :role, optional: true

  def adminit_access?
    role.present?
  end
end
