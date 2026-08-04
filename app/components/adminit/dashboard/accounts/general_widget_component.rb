module Adminit
  module Dashboard
    module Accounts
      class GeneralWidgetComponent < ApplicationViewComponent
        option :account

        def search_url
          helpers.adminit_dashboard_accounts_search_path
        end

        # URL template with a placeholder id — the account-lookup Stimulus
        # controller swaps "__id__" for the selected account id.
        def summary_url
          helpers.adminit_dashboard_account_summary_path(id: "__id__")
        end
      end
    end
  end
end
