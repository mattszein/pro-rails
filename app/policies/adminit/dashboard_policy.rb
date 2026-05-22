module Adminit
  class DashboardPolicy < ApplicationPolicy
    self.identifier = :"Adminit::DashboardPolicy"
    POLICY_RESOURCE = :dashboard

    def show?
      user.adminit_access?
    end
  end
end
