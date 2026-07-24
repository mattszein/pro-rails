module Adminit
  module Accounts
    # Renders an account's identity summary (id, email, role, status, created).
    # Used on the account show page and in the dashboard account-lookup frame.
    class SummaryComponent < ApplicationViewComponent
      option :account

      def status_theme(status)
        helpers.account_status_theme(status)
      end
    end
  end
end
