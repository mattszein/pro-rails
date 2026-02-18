class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def user?
    user.present?
  end

  def mark_all_read?
    user.present?
  end

  def mark_as_read?
    user.present? && record.recipient_id == user.id && record.recipient_type == "Account"
  end
end
