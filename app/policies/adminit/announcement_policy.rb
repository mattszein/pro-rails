module Adminit
  class AnnouncementPolicy < ApplicationPolicy
    self.identifier = :"Adminit::AnnouncementPolicy"

    def destroy?
      manage? && record.destroyable?
    end

    def update?
      manage? && record.editable?
    end

    def edit?
      update?
    end

    def publish?
      manage? && record.draft?
    end

    def draft?
      manage? && record.can_transition_to_draft?
    end
  end
end
