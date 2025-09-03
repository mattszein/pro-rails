class Adminit::RolesController < Adminit::ApplicationController
  before_action :set_role, only: [:remove_account, :add_account, :account_select]

  def index
    authorize!
    @roles = Role.all
  end

  def show
    @role = Role.includes(:accounts).find(params[:id])
    authorize!
  end

  def remove_account
    authorize! @role
    us = Account.find(params[:account_id])
    us.role = nil
    if us.save
      flash[:notice] = "account was successfully removed from the role."
    else
      flash[:alert] = "account wasn't removed from the role."
    end
    redirect_to adminit_role_path(@role)
  end

  def account_select
    authorize!
  end

  def add_account
    authorize! @role
    account = Account.find_by(email: role_params[:email])
    if account.role.nil?
      if account.update(role: @role)
        flash[:notice] = "account was successfully added to the role."
      else
        flash[:alert] = "account wasn't added to the role."
      end
    else
      flash[:alert] = "account already has a role."
    end
    redirect_to adminit_role_path(@role)
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:email)
  end
end
