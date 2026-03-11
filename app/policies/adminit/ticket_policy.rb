module Adminit
  class TicketPolicy < ApplicationPolicy
    POLICY_RESOURCE = :ticket
    self.identifier = :"Adminit::TicketPolicy"

    # Allow admins to take unassigned tickets regardless of status
    def take?
      manage? && record.assigned_id.nil?
    end

    # Allow admins to leave tickets they're assigned to
    def leave?
      manage? && record.assigned_id == user.id
    end

    def finish?
      manage? && (record.in_progress? || record.reopened?) && (record.assigned_id == user.id || user.role&.name == "superadmin")
    end

    def accept_reopen?
      manage? && record.reopen_requested? && (record.assigned_id == user.id || user.role&.name == "superadmin")
    end

    def reject_reopen?
      manage? && record.reopen_requested? && (record.assigned_id == user.id || user.role&.name == "superadmin")
    end

    def reopen?
      manage? && record.finished? && (record.assigned_id == user.id || user.role&.name == "superadmin")
    end

    # Allow admins to update tickets they've been assigned to
    def update?
      manage? && (record.assigned_id == user.id || user.role&.name == "superadmin")
    end

    # Admins cannot attach files - only ticket creators can
    def attach_files?
      false
    end
  end
end
