module Adminit
  class AiPlaybookPolicy < ApplicationPolicy
    POLICY_RESOURCE = :support_ai
    self.identifier = :"Adminit::AiPlaybookPolicy"
  end
end
