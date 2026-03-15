class Adminit::PermissionsController < Adminit::ApplicationController
  before_action :set_permission, only: %i[update]

  # GET /adminit/permissions
  def index
    authorize!
    @roles = Role.all.collect { |p| [p.name, p.id] }
    @permissions = Permission.all
  end

  # /PUT /adminit/permissions/:id
  def update
    authorize! @permission, with: Adminit::PermissionPolicy, context: {role_ids: permission_params[:role_ids]}
    begin
      @permission.role_ids = permission_params[:role_ids]
      if @permission.save
        flash[:notice] = I18n.t("adminit.permissions.updated")
      else
        flash[:alert] = I18n.t("adminit.permissions.not_updated")
      end
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = I18n.t("adminit.permissions.invalid_roles")
    end
    redirect_to adminit_permissions_path
  end

  private

  def set_permission
    @permission = Permission.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def permission_params
    params.require(:permission).permit(:permission_id, role_ids: [])
  end
end
