module Adminit
  module Dashboard
    class AccountsController < Adminit::ApplicationController
      include Adminit::AccountSearchable

      before_action :require_account
      before_action :ensure_frame_response, only: :summary

      # TomSelect options for the account lookup widget: minimal {value, text}
      # pairs — the selected account's summary is rendered by #summary.
      def search
        authorize! Account, to: :show?, with: Adminit::AccountPolicy
        search_accounts_json(limit: 10, value: ->(account) { account.id.to_s })
      end

      # Frame-only endpoint: renders the selected account's summary.
      def summary
        @account = Account.find(params[:id])
        authorize! @account, to: :show?, with: Adminit::AccountPolicy
      end
    end
  end
end
