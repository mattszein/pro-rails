module Adminit
  class RolePolicy < ApplicationPolicy
    self.identifier = :"Adminit::RolePolicy"
    def remove_account?
      return false unless manage?
      !(@record.id == 1 && user.role == @record && @record.accounts.length == 1)
    end
  end
end
