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
    authorize!
    @permission.role_ids = permission_params[:role_ids]
    if @permission.save
      flash[:notice] = "Role was successfully updated."
    else
      flash[:alert] = "Role wasn't updated."
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
