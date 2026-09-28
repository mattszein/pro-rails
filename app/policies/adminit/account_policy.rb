module Adminit
  class AccountPolicy < ApplicationPolicy
    POLICY_RESOURCE = :account
    self.identifier = :"Adminit::AccountPolicy"

    # Shared account-lookup endpoint (roles, feature flags, dashboard) — any
    # role permitted to manage one of its callers can use it.
    def search?
      get_access(:account) || get_access(:role) || get_access(:feature_flag)
    end
  end
end
