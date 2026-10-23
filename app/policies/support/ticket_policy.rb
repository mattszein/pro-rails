# frozen_string_literal: true

module Support
  class TicketPolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def new?
      user.present?
    end

    def create?
      user.present?
    end

    # Users can only view their own tickets
    def show?
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

    def request_reopen?
      record.created_id == user.id && record.finished?
    end

    # "This solved it": only the requester, while the assistant is waiting for them.
    def resolve_with_ai?
      record.created_id == user.id && record.open? && record.ai_awaiting_user?
    end

    # "Talk to a person": only the requester, while the assistant is engaged and not yet handed off.
    def request_human?
      record.created_id == user.id && (record.ai_analyzing? || record.ai_awaiting_user?)
    end
  end
end
