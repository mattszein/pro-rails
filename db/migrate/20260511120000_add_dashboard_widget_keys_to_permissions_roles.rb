class AddDashboardWidgetKeysToPermissionsRoles < ActiveRecord::Migration[8.0]
  def change
    add_column :permissions_roles, :dashboard_widget_keys, :jsonb, default: [], null: false
    add_index :permissions_roles, :dashboard_widget_keys, using: :gin
  end
end
