module Adminit
  module Accounts
    # Renders an account's identity summary (id, email, role, status, created).
    #
    # Used in two modes:
    #   * bound    – `account:` given, renders the real values (account show page)
    #   * template – `account:` omitted, renders empty slots tagged with
    #                `data-account-field` / `data-account-status` so JavaScript can
    #                fill them when cloned from a <template> (dashboard lookup widget)
    class SummaryComponent < ApplicationViewComponent
      option :account, default: -> {}

      def template_mode?
        account.nil?
      end

      def statuses
        Account.statuses.keys
      end

      def status_theme(status)
        helpers.account_status_theme(status)
      end
    end
  end
end
