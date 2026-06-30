module Adminit
  module Dashboard
    module Accounts
      class GeneralWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        option :account

        def title
          I18n.t("adminit.dashboard_widgets.accounts.general.title")
        end

        def search_url
          helpers.adminit_dashboard_accounts_search_path
        end
      end
    end
  end
end
