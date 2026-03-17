class Adminit::RolesController < Adminit::ApplicationController
  before_action :set_role, only: [:remove_account, :add_account, :account_select, :search_accounts]
  verify_authorized

  def index
    authorize!
    @roles = Role.all
  end

  def show
    @role = Role.includes(:accounts, :permissions).find(params[:id])
    authorize! @role
  end

  def remove_account
    authorize! @role
    account = Account.find(params[:account_id])
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
    result = Adminit::Roles::AddMember.call(role: @role, email: role_params[:email])
    if result.success?
      redirect_to adminit_role_path(@role), notice: I18n.t("adminit.roles.account_added")
    else
      redirect_to adminit_role_path(@role), alert: result.error
    end
  end

  def search_accounts
    authorize!
    query = params[:q].to_s.strip
    return render(json: []) if query.length < 2

    accounts = Account.search_by_email(query).not_in_role(@role).limit(50)
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
