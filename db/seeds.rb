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
role_superadmin = Role.create(name: "superadmin")
role_support = Role.create(name: "support")

Account.create(email: "matt@matt.com", role_id: role_superadmin.id, password_hash: RodauthApp.rodauth.allocate.password_hash("password"), status: "verified")
Account.create(email: "matinger@gmail.com", role_id: role_support.id, password_hash: RodauthApp.rodauth.allocate.password_hash("password"), status: "verified")
Account.create(email: "user@user.com", role_id: nil, password_hash: RodauthApp.rodauth.allocate.password_hash("password"), status: "verified")

app_permission = Permission.create(resource: Adminit::ApplicationPolicy.identifier)
account_permission = Permission.create(resource: Adminit::AccountPolicy.identifier)
ticket_permission = Permission.create(resource: Adminit::TicketPolicy.identifier)

role_superadmin.permissions << app_permission
role_superadmin.permissions << account_permission
role_superadmin.permissions << Permission.create(resource: Adminit::RolePolicy.identifier)
role_superadmin.permissions << Permission.create(resource: Adminit::PermissionPolicy.identifier)
role_superadmin.permissions << ticket_permission

role_support.permissions << app_permission
role_support.permissions << account_permission
role_support.permissions << ticket_permission
