# app/policies/message_policy.rb
class MessagePolicy < ApplicationPolicy
  # Allow creating messages if the user is either the ticket creator or assignee
  def create?
    return false unless record.conversation&.ticket

    ticket = record.conversation.ticket
    user.id == ticket.created_id || user.id == ticket.assigned_id
  end

  # Only the message author can update their own messages
  def update?
    record.account_id == user.id
  end

  # Only the message author or admins can delete messages
  def destroy?
    record.account_id == user.id || user.adminit_access?
  end

  # Anyone who can view the ticket can view its messages
  def show?
    return false unless record.conversation&.ticket

    ticket = record.conversation.ticket
    user.id == ticket.created_id || user.id == ticket.assigned_id || user.adminit_access?
  end
end
