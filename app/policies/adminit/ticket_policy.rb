module Adminit
  class TicketPolicy < ApplicationPolicy
    self.identifier = :"Adminit::TicketPolicy"

    # Allow admins to take unassigned tickets regardless of status
    def take?
      manage? && record.assigned_id.nil?
    end

    # Allow admins to leave tickets they're assigned to
    def leave?
      manage? && record.assigned_id == user.id
    end

    # Allow admins to update tickets they've been assigned to
    def update?
      manage? && (record.assigned_id == user.id || user.role&.name == "superadmin")
    end
  end
end
