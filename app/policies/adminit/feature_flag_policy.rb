module Adminit
  class FeatureFlagPolicy < ApplicationPolicy
    POLICY_RESOURCE = :feature_flag
    self.identifier = :"Adminit::FeatureFlagPolicy"
  end
end
