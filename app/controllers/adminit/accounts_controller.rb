class Adminit::AccountsController < Adminit::ApplicationController
  include Tableable

  before_action :set_account, only: %i[show edit destroy]
  verify_authorized

  def index
    authorize!
    @columns = helpers.accounts_columns
    @pagy, @accounts = apply_table_params(
      Account.includes(:role).order(created_at: :desc),
      columns: @columns
    )
  end

  def show
    @remember_key = AccountRememberKey.find_by(id: @account.id)
    @tickets_created_count = Support::Ticket.where(created_id: @account.id).count
    @tickets_assigned_count = Support::Ticket.where(assigned_id: @account.id).count
  end

  def edit
  end

  # Shared lookup for every admin screen that offers a searchable account
  # picker (roles, feature flags, dashboard) — each caller narrows the scope
  # with its own params rather than getting its own action.
  def search
    authorize! to: :search?
    query = params[:q].to_s.strip
    return render(json: []) if query.length < 2

    accounts = Account.search_by_email(query)
    accounts = accounts.not_in_role(Role.find(params[:not_in_role])) if params[:not_in_role].present?
    accounts = accounts.where.not(status: :closed) if params[:exclude_closed].present?

    render json: accounts.limit(20).map { |account| {value: account.id.to_s, text: account.email} }
  end

  def destroy
    @account.destroy!

    respond_to do |format|
      format.html { redirect_to adminit_accounts_url, notice: I18n.t("adminit.accounts.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  def set_account
    @account = Account.find(params[:id])
    authorize! @account
  end
end
