class Role < ApplicationRecord
  validates :name, presence: true
  has_many :accounts
  has_and_belongs_to_many :permissions # rubocop:disable Rails/HasAndBelongsToMany
  SUPERADMIN = "superadmin"

  def self.superadmin
    Role.find_by(name: SUPERADMIN)
  end

  def superadmin?
    name == SUPERADMIN
  end

  def permitted_resources
    @permitted_resources ||= permissions.pluck(:resource).to_set
  end

  def permitted?(resource_key)
    permitted_resources.include?(resource_key.to_s)
  end
end
