module Adminit
  class FeatureFlagPolicy < ApplicationPolicy
    POLICY_RESOURCE = :feature_flag
    self.identifier = :"Adminit::FeatureFlagPolicy"

    # Flags are declared in code, never created or destroyed in Adminit
    # (S30) — the routes expose no create/destroy path either, so this is
    # belt-and-braces, assertable directly in a policy spec.
    def create? = false

    def destroy? = false
  end
end
