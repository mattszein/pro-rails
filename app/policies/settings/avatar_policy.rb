module Settings
  class AvatarPolicy < ApplicationPolicy
    default_rule :manage?

    def index? = true
    def create? = true
    def manage? = own_record?
    def show? = manage?
    def update? = manage?
    def generate? = manage?
    def select? = manage?
    def evolve? = manage?
    def toggle_visibility? = manage?

    private

    def own_record?
      record.profile_id == user.profile.id
    end
  end
end
