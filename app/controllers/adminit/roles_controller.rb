class Adminit::RolesController < Adminit::ApplicationController
  before_action :set_role, only: [:remove_account, :add_account, :account_select]
  verify_authorized

  def index
    authorize!
    @pagy, @roles = pagy(Role.all)
  end

  def show
    @role = Role.includes(:accounts, :permissions).find(params[:id])
    authorize! @role
  end

  def remove_account
    authorize! @role
    account = @role.accounts.find(params[:account_id])
    account.role = nil
    if account.save
      redirect_to adminit_role_path(@role), notice: I18n.t("adminit.roles.account_removed")
    else
      redirect_to adminit_role_path(@role), alert: I18n.t("adminit.roles.account_not_removed")
    end
  end

  def account_select
    authorize!
  end

  def add_account
    authorize! @role
    account = Account.find_by(id: params.dig(:role, :account_id))

    if account.nil?
      redirect_to adminit_role_path(@role), alert: I18n.t("adminit.roles.account_not_found")
    elsif account.role == @role
      redirect_to adminit_role_path(@role), alert: I18n.t("adminit.roles.account_already_in_role")
    elsif account.update(role: @role)
      redirect_to adminit_role_path(@role), notice: I18n.t("adminit.roles.account_added")
    else
      redirect_to adminit_role_path(@role), alert: account.errors.full_messages.to_sentence
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end
end
