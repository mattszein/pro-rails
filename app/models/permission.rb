class Permission < ApplicationRecord
  has_and_belongs_to_many :roles # rubocop:disable Rails/HasAndBelongsToMany

  validates :resource, presence: true, uniqueness: true
  validates :roles, presence: true

  default_scope { order(resource: :asc) }
  def self.default
    find_by(resource: Adminit::ApplicationPolicy.identifier)
  end
end
