module Adminit
  module Dashboard
    module Accounts
      class GeneralWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        option :account

        def search_url
          helpers.adminit_dashboard_accounts_search_path
        end
      end
    end
  end
end
