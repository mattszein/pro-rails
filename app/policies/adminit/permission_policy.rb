module Adminit
  class PermissionPolicy < ApplicationPolicy
    self.identifier = :"Adminit::PermissionPolicy"
    authorize :role_ids, optional: true

    def update?
      return false unless get_access(self.class.identifier)
      return false unless @record.is?(Adminit::PermissionPolicy) && role_ids&.include?(Role.superadmin&.id.to_s)
      true
    end
  end
end
