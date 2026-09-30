module Adminit
  module Dashboard
    class AccountsController < Adminit::ApplicationController
      before_action :require_account
      before_action :ensure_frame_response, only: :summary

      # Frame-only endpoint: renders the selected account's summary.
      def summary
        @account = Account.find(params[:id])
        authorize! @account, to: :show?, with: Adminit::AccountPolicy
      end
    end
  end
end
