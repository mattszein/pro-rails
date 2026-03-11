module Adminit
  class AnnouncementPolicy < ApplicationPolicy
    POLICY_RESOURCE = :announcement
    self.identifier = :"Adminit::AnnouncementPolicy"
  end
end
