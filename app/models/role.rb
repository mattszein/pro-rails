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
end
