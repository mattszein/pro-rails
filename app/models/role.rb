class Role < ApplicationRecord
  validates :name, presence: true
  has_many :accounts
  has_and_belongs_to_many :permissions # rubocop:disable Rails/HasAndBelongsToMany
end
