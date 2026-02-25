module Adminit
  class PermissionPolicy < ApplicationPolicy
    self.identifier = :"Adminit::PermissionPolicy"
    authorize :role_ids, optional: true

    def update?
      # Return false if the user doesn't have access to the permission policy
      # Return false if the record is a PermissionPolicy and the superadmin role is not included in the role_ids. This prevent removing the superadmin role from permissions.
      return false unless get_access(self.class.identifier)
      return false if (@record.is?(Adminit::PermissionPolicy) || @record.is?(Adminit::ApplicationPolicy)) && !role_ids&.include?(Role.superadmin&.id.to_s)
      true
    end
  end
end
