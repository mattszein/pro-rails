class Permission < ApplicationRecord
  has_and_belongs_to_many :roles # rubocop:disable Rails/HasAndBelongsToMany

  default_scope { order(resource: :asc) }
  def self.default
    find_by(resource: Adminit::ApplicationPolicy.identifier)
  end
end
