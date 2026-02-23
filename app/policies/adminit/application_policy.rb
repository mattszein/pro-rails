class Adminit::ApplicationPolicy < ActionPolicy::Base
  default_rule :manage?
  alias_rule :index?, :create?, to: :manage?

  self.identifier = :"Adminit::ApplicationPolicy"

  def manage?
    get_access(self.class.identifier)
  end

  private

  # Define shared methods useful for most policies.
  # For example:
  #
  #  def owner?
  #    record.user_id == user.id
  #  end

  def get_access(key = identifier)
    return false unless user&.role
    user.role.permissions.exists?(resource: key)
  end
end
