module Adminit
  class AudiencePolicy < ApplicationPolicy
    POLICY_RESOURCE = :audience
    self.identifier = :"Adminit::AudiencePolicy"
  end
end
