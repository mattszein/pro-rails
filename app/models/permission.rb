class Permission < ApplicationRecord
  RESOURCE_REGISTRY = {
    application: 0,
    account: 1,
    role: 2,
    permission: 3,
    announcement: 4,
    ticket: 5
  }.freeze

  enum :resource, RESOURCE_REGISTRY, prefix: :resource

  has_and_belongs_to_many :roles # rubocop:disable Rails/HasAndBelongsToMany

  validates :resource, presence: true, uniqueness: true
  validates :roles, presence: true

  default_scope { order(resource: :asc) }

  def self.default
    find_by(resource: :application)
  end

  def is?(klass)
    resource == klass::POLICY_RESOURCE.to_s
  end
end
