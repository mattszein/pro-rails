# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
role_superadmin = Role.find_or_create_by!(name: "superadmin")
role_support = Role.find_or_create_by!(name: "support")

# Create accounts
Account.find_or_create_by!(email: "matt@matt.com") do |account|
  account.role = role_superadmin
  account.password_hash = RodauthApp.rodauth.allocate.password_hash("password")
  account.status = "verified"
end

Account.find_or_create_by!(email: "matinger@gmail.com") do |account|
  account.role = role_support
  account.password_hash = RodauthApp.rodauth.allocate.password_hash("password")
  account.status = "verified"
end

Account.find_or_create_by!(email: "user@user.com") do |account|
  account.role = nil
  account.password_hash = RodauthApp.rodauth.allocate.password_hash("password")
  account.status = "verified"
end

# Create permissions and ensure roles are assigned idempotently
{
  application: [role_superadmin, role_support],
  account: [role_superadmin, role_support],
  ticket: [role_superadmin, role_support],
  role: [role_superadmin],
  announcement: [role_superadmin],
  permission: [role_superadmin]
}.each do |resource, roles|
  permission = Permission.find_or_create_by!(resource: resource) do |p|
    p.roles = roles
  end
  permission.roles = roles
end

# Configure dashboard widgets per role/permission
# Superadmin gets all widgets for all resources
superadmin_widgets = {
  ticket: ["tickets_personal", "tickets_general", "tickets_analytics"],
  announcement: ["announcements_general", "announcements_analytics"],
  permission: ["permissions_overview"]
}

support_widgets = {
  ticket: ["tickets_personal", "tickets_general", "tickets_analytics"]
}

[role_superadmin, role_support].each do |role|
  widgets_for_role = (role == role_superadmin) ? superadmin_widgets : support_widgets

  widgets_for_role.each do |resource, widget_keys|
    permission = Permission.find_by!(resource: resource)
    PermissionRole.where(permission_id: permission.id, role_id: role.id)
      .update_all(dashboard_widget_keys: widget_keys)
  end
end
