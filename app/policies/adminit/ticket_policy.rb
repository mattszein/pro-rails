module Adminit
  class TicketPolicy < ApplicationPolicy
    self.identifier = :"Adminit::TicketPolicy"

    # Allow admins to take open tickets
    def take?
      manage? && record.open?
    end

    # Allow admins to update tickets they've been assigned to
    def update?
      manage? && (record.assigned_id == user.id || user.role&.name == "superadmin")
    end
  end
end
