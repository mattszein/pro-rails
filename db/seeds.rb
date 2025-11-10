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

# Create permissions with roles assigned from the start
Permission.find_or_create_by!(resource: Adminit::ApplicationPolicy.identifier) do |permission|
  permission.roles = [role_superadmin, role_support]
end

Permission.find_or_create_by!(resource: Adminit::AccountPolicy.identifier) do |permission|
  permission.roles = [role_superadmin, role_support]
end

Permission.find_or_create_by!(resource: Adminit::TicketPolicy.identifier) do |permission|
  permission.roles = [role_superadmin, role_support]
end

Permission.find_or_create_by!(resource: Adminit::RolePolicy.identifier) do |permission|
  permission.roles = [role_superadmin]
end

Permission.find_or_create_by!(resource: Adminit::PermissionPolicy.identifier) do |permission|
  permission.roles = [role_superadmin]
end
