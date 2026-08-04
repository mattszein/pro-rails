class PermissionRole < ApplicationRecord
  self.table_name = "permissions_roles"
  self.primary_key = [:permission_id, :role_id]

  belongs_to :permission
  belongs_to :role

  validate :widget_keys_known_to_registry
  validate :widget_keys_match_permission_resource

  def enabled_widgets
    Dashboard::WidgetRegistry.for_keys(dashboard_widget_keys)
  end

  private

  def widget_keys_known_to_registry
    invalid = dashboard_widget_keys - Dashboard::WidgetRegistry.all_keys.map(&:to_s)
    return if invalid.empty?

    errors.add(
      :dashboard_widget_keys,
      I18n.t("activerecord.errors.models.permission_role.attributes.dashboard_widget_keys.unknown",
        keys: invalid.join(", "))
    )
  end

  def widget_keys_match_permission_resource
    return if dashboard_widget_keys.empty?

    permission_resource = permission&.resource&.to_sym
    mismatched = dashboard_widget_keys.filter_map do |key|
      widget = Dashboard::WidgetRegistry.find(key)
      (widget&.resource != permission_resource) ? key : nil
    end
    return if mismatched.empty?

    errors.add(
      :dashboard_widget_keys,
      I18n.t("activerecord.errors.models.permission_role.attributes.dashboard_widget_keys.resource_mismatch",
        keys: mismatched.join(", "))
    )
  end
end
