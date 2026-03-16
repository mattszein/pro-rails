class Adminit::RolesController < Adminit::ApplicationController
  before_action :set_role, only: [:remove_account, :add_account, :account_select, :search_accounts]
  verify_authorized

  def index
    authorize!
    @roles = Role.all
  end

  def show
    @role = Role.includes(:accounts, :permissions).find(params[:id])
    authorize!
  end

  def remove_account
    authorize! @role
    us = Account.find(params[:account_id])
    us.role = nil
    if us.save
      flash[:notice] = I18n.t("adminit.roles.account_removed")
    else
      flash[:alert] = I18n.t("adminit.roles.account_not_removed")
    end
    redirect_to adminit_role_path(@role)
  end

  def account_select
    authorize!
  end

  def add_account
    authorize! @role
    account = Account.find_by(email: role_params[:email])
    if account.update(role: @role)
      flash[:notice] = I18n.t("adminit.roles.account_added")
    else
      flash[:alert] = I18n.t("adminit.roles.account_not_added")
    end
    redirect_to adminit_role_path(@role)
  end

  def search_accounts
    authorize!
    query = params[:q].to_s.strip
    accounts = Account.where("email ILIKE ?", "%#{query}%")
      .where.not(id: @role.account_ids)
      .limit(10)
    render json: accounts.map { |a| {value: a.email, text: a.email} }
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:email)
  end
end
