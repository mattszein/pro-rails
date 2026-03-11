module Adminit
  class AccountPolicy < ApplicationPolicy
    POLICY_RESOURCE = :account
    self.identifier = :"Adminit::AccountPolicy"
  end
end
