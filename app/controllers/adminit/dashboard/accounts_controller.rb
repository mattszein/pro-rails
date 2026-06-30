module Adminit
  module Dashboard
    class AccountsController < Adminit::ApplicationController
      before_action :require_account

      def search
        authorize! Account, to: :show?, with: Adminit::AccountPolicy
        query = params[:q].to_s.strip
        return render(json: []) if query.length < 2

        accounts = Account.search_by_email(query).includes(:role).limit(10)
        render json: accounts.map { |a| serialize_account(a) }
      end

      private

      def serialize_account(account)
        {
          value: account.id.to_s,
          text: account.email,
          id: account.id,
          email: account.email,
          role: account.role&.name || I18n.t("adminit.dashboard_widgets.accounts.general.no_role"),
          status_key: account.status,
          created_at: I18n.l(account.created_at.to_date, format: :long),
          account_path: adminit_account_path(account)
        }
      end
    end
  end
end
