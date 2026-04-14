# frozen_string_literal: true

module Settings
  class AvatarPolicy < ApplicationPolicy
    def index?
      true
    end

    def create?
      true
    end

    def show?
      own_record?
    end

    def update?
      own_record?
    end

    def generate?
      own_record?
    end

    def select?
      own_record?
    end

    def evolve?
      own_record?
    end

    def toggle_visibility?
      own_record?
    end

    private

    def own_record?
      record.profile_id == user.profile.id
    end
  end
end
