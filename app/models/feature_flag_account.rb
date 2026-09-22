class FeatureFlagAccount < ApplicationRecord
  belongs_to :feature_flag
  belongs_to :account

  enum :access, {blocked: 0, allowed: 1}, validate: {allow_nil: false}

  validates :account_id, uniqueness: {scope: :feature_flag_id}
end
