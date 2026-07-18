class Adminit::PermissionsController < Adminit::ApplicationController
  before_action :set_permission, only: %i[update]

  # GET /adminit/permissions
  def index
    authorize!
    @roles = Role.all.to_a
    @permissions = Permission.all.to_a
    @permission_roles = PermissionRole.where(permission_id: @permissions.map(&:id))
      .index_by { |pr| [pr.permission_id, pr.role_id] }
  end

  # /PUT /adminit/permissions/:id
  def update
    authorize! @permission, with: Adminit::PermissionPolicy, context: {role_ids: permission_params[:role_ids]}
    begin
      ApplicationRecord.transaction do
        @permission.role_ids = permission_params[:role_ids]
        @permission.save!
        update_dashboard_widget_keys
      end
      flash[:notice] = I18n.t("adminit.permissions.updated")
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = I18n.t("adminit.permissions.invalid_roles")
    rescue ActiveRecord::RecordInvalid
      flash[:alert] = I18n.t("adminit.permissions.not_updated")
    end
    redirect_to adminit_permissions_path
  end

  private

  def set_permission
    @permission = Permission.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def permission_params
    params.require(:permission).permit(:permission_id, role_ids: [], dashboard_widget_keys: {})
  end

  # Unchecked checkboxes submit nothing, so a role absent from the
  # dashboard_widget_keys param means "no widgets" — clear, don't skip.
  # update! (not update_all) so PermissionRole validates the keys.
  def update_dashboard_widget_keys
    return if Dashboard::WidgetRegistry.for_resource(@permission.resource).empty?

    submitted = permission_params[:dashboard_widget_keys] || {}
    permission_params[:role_ids]&.each do |role_id|
      next if role_id.blank?

      permission_role = PermissionRole.find_by(permission_id: @permission.id, role_id: role_id)
      permission_role&.update!(dashboard_widget_keys: Array(submitted[role_id]).compact_blank)
    end
  end
end
