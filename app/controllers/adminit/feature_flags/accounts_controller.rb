module Adminit
  module FeatureFlags
    # Each action is a single-row write with no side effect beyond that row
    # (TECH-PLAN §3.5) — no interactor, no stamp: the flag carries no
    # attribution column to coordinate.
    class AccountsController < Adminit::ApplicationController
      include Adminit::AccountSearchable

      before_action :set_feature_flag

      # Updates the existing entry's access in place when the account is
      # already listed, rather than deleting and recreating it — an
      # operator changing an allow into a block does not have to find and
      # remove the earlier row first. The unique index guarantees one row
      # either way (S9).
      def create
        account = Account.find(params[:account_id])
        entry = @feature_flag.account_entries.find_or_initialize_by(account: account)
        entry.access = params[:access]

        if entry.save
          redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.account_entry_added")
        else
          redirect_to adminit_feature_flag_path(@feature_flag), alert: entry.errors.full_messages.to_sentence
        end
      end

      def destroy
        account = Account.find(params[:id])
        @feature_flag.account_entries.where(account: account).delete_all

        redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.account_entry_removed")
      end

      # A closed account can never be granted (S14), so it is never
      # offerable here — narrower than the roles screen's own search, which
      # only excludes accounts already in the role being edited.
      def search
        search_accounts_json(scope: Account.where.not(status: :closed), limit: 50, value: ->(account) { account.id.to_s })
      end

      private

      def set_feature_flag
        @feature_flag = FeatureFlag.find(params[:feature_flag_id])
        authorize! @feature_flag, to: :update?, with: Adminit::FeatureFlagPolicy
      end
    end
  end
end
