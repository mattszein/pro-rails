class FeatureFlagAudience < ApplicationRecord
  belongs_to :feature_flag
  belongs_to :audience

  validates :audience_id, uniqueness: {scope: :feature_flag_id}
end
