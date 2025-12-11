# frozen_string_literal: true

module Support
  class TicketPolicy < ApplicationPolicy
    # Users can only view their own tickets
    def show?
      record.created_id == user.id
    end

    # Users can only update their own tickets
    def update?
      record.created_id == user.id
    end

    # Users can only destroy their own tickets
    def destroy?
      record.created_id == user.id
    end

    # Users can only attach files to their own tickets
    def attach_files?
      record.created_id == user.id
    end
  end
end
