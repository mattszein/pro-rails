module Adminit
  module Roles
    class AddMember
      include Interactor

      delegate :role, :email, to: :context

      def call
        validate!
        account.update!(role: role)
      rescue ActiveRecord::RecordInvalid => e
        context.fail!(error: e.message)
      end

      private

      def validate!
        context.fail!(error: I18n.t("adminit.roles.account_not_found")) unless account
        context.fail!(error: I18n.t("adminit.roles.account_already_in_role")) if account.role == role
      end

      def account
        @account ||= Account.find_by(email: email)
      end
    end
  end
end
