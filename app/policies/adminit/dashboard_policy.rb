module Adminit
  class DashboardPolicy < ApplicationPolicy
    self.identifier = :"Adminit::DashboardPolicy"

    # Not backed by Permission::RESOURCE_REGISTRY / get_access — the dashboard
    # is the adminit landing page, gated only on adminit_access?. Which widgets
    # it shows is a separate per-widget authorize! against each widget's own
    # policy (see Adminit::DashboardsController#widget).
    def show?
      user.adminit_access?
    end
  end
end
