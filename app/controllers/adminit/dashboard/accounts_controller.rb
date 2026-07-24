module Adminit
  module Dashboard
    class AccountsController < Adminit::ApplicationController
      before_action :require_account
      before_action :ensure_frame_response, only: :summary

      # TomSelect options for the account lookup widget: minimal {value, text}
      # pairs — the selected account's summary is rendered by #summary.
      def search
        authorize! Account, to: :show?, with: Adminit::AccountPolicy
        query = params[:q].to_s.strip
        return render(json: []) if query.length < 2

        accounts = Account.search_by_email(query).limit(10)
        render json: accounts.map { |a| {value: a.id.to_s, text: a.email} }
      end

      # Frame-only endpoint: renders the selected account's summary.
      def summary
        @account = Account.find(params[:id])
        authorize! @account, to: :show?, with: Adminit::AccountPolicy
      end
    end
  end
end
