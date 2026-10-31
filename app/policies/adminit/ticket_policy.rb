module Adminit
  class TicketPolicy < ApplicationPolicy
    POLICY_RESOURCE = :ticket
    self.identifier = :"Adminit::TicketPolicy"

    # Unassigned tickets that are open or waiting on a reopen decision. Finished/closed tickets
    # go back through the reopen flows instead.
    def take?
      manage? && record.assigned_id.nil? && (record.open? || record.reopen_requested? || record.reopened?)
    end

    # Assignees can step away from tickets they are actively working on.
    def leave?
      manage? && record.assigned_id == user.id && (record.in_progress? || record.reopened?)
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
