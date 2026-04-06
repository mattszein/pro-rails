module Settings
  class ProfilePolicy < ApplicationPolicy
    def update?
      record.account_id == user.id
    end

    def edit?
      update?
    end
  end
end
