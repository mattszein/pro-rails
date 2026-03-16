class Adminit::AccountsController < Adminit::ApplicationController
  before_action :set_account, only: %i[show edit destroy]
  verify_authorized

  def index
    authorize!
    @accounts = Account.all
  end

  def show
    @remember_key = AccountRememberKey.find_by(id: @account.id)
    @tickets_created_count = Support::Ticket.where(created_id: @account.id).count
    @tickets_assigned_count = Support::Ticket.where(assigned_id: @account.id).count
  end

  def edit
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
