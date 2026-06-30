# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
role_superadmin = Role.find_or_create_by!(name: "superadmin")
role_support = Role.find_or_create_by!(name: "support")

password_hash = RodauthApp.rodauth.allocate.password_hash("password")

# Core demo accounts
Account.find_or_create_by!(email: "matt@matt.com") do |account|
  account.role = role_superadmin
  account.password_hash = password_hash
  account.status = "verified"
end

Account.find_or_create_by!(email: "matinger@gmail.com") do |account|
  account.role = role_support
  account.password_hash = password_hash
  account.status = "verified"
end

Account.find_or_create_by!(email: "user@user.com") do |account|
  account.role = nil
  account.password_hash = password_hash
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
superadmin_widgets = {
  ticket: ["tickets_analytics"],
  announcement: ["announcements_analytics"],
  account: ["accounts_general", "accounts_analytics"],
  role: ["roles_general"]
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

# Demo data: 30 users, backdated tickets and announcements so dashboards have data
if Rails.env.development? || ENV["SEED_DEMO_DATA"] == "true"
  demo_users = 30.times.map do |i|
    created_at = rand(1..30).days.ago
    Account.find_or_create_by!(email: "demo#{i + 1}@example.com") do |account|
      account.role = nil
      account.password_hash = password_hash
      account.status = "verified"
      account.created_at = created_at
    end
  end

  support_agents = [Account.find_by(email: "matt@matt.com"), Account.find_by(email: "matinger@gmail.com")].compact
  superadmin_account = Account.find_by(email: "matt@matt.com")

  ticket_statuses = %i[open in_progress finished closed reopened reopen_requested]
  ticket_categories = %i[account_access technical_issue billing feature_request other]

  ticket_titles = [
    "Cannot log in to my account",
    "Password reset email not received",
    "Two-factor authentication broken",
    "Billing question about last invoice",
    "Refund request for duplicate charge",
    "Feature request: dark mode export",
    "Dashboard not loading on Safari",
    "Permission denied when uploading file",
    "Email notifications stopped arriving",
    "Subscription plan upgrade help",
    "Account deletion request",
    "Profile picture won't upload",
    "Slow performance on reports page",
    "Mobile app crash on startup",
    "Cannot invite team members",
    "Integration with third-party service fails",
    "Export to CSV missing rows",
    "Time zone displayed incorrectly",
    "API rate limit increase request",
    "Lost access after email change"
  ]

  if Support::Ticket.count < 40
    50.times do |i|
      creator = demo_users.sample
      status = ticket_statuses.sample
      created_at = rand(1..45).days.ago
      assignee = (status == :open) ? nil : support_agents.sample

      ticket = Support::Ticket.new(
        title: "#{ticket_titles.sample} (##{i + 1})",
        description: "Reported by #{creator.email}. This is sample seed data for the admin dashboard.",
        priority: rand(1..5),
        status: status,
        category: ticket_categories.sample,
        created: creator,
        assigned: assignee
      )
      ticket.save!
      resolution_delta = rand(2..72).hours
      ticket.update_columns(
        created_at: created_at,
        updated_at: %i[finished closed].include?(status) ? created_at + resolution_delta : created_at + rand(0..24).hours
      )
    end
  end

  if superadmin_account && Announcement.count < 8
    announcement_data = [
      {title: "Scheduled maintenance this Sunday", status: :published, days_ago: 25},
      {title: "New billing dashboard now live", status: :published, days_ago: 18},
      {title: "Two-factor authentication is now required", status: :published, days_ago: 10},
      {title: "Holiday support hours", status: :published, days_ago: 4},
      {title: "Upcoming API deprecation notice", status: :scheduled, days_ago: 2, scheduled_in: 3},
      {title: "Quarterly product review", status: :scheduled, days_ago: 1, scheduled_in: 7},
      {title: "Internal: dashboard redesign rollout", status: :draft, days_ago: 6},
      {title: "Draft: end-of-year recap", status: :draft, days_ago: 0}
    ]

    announcement_data.each_with_index do |data, index|
      created_at = data[:days_ago].days.ago
      announcement = Announcement.new(
        reference: "DEMO-#{Time.current.to_i}-#{index}",
        title: data[:title],
        body: "Body for #{data[:title]}. Seed data for the dashboard demo.",
        rich_body: "<p>Body for <strong>#{data[:title]}</strong>. Seed data for the dashboard demo.</p>",
        status: data[:status],
        author: superadmin_account,
        scheduled_at: data[:scheduled_in]&.days&.from_now,
        published_at: (data[:status] == :published) ? created_at : nil
      )
      announcement.save!
      announcement.update_columns(created_at: created_at, updated_at: created_at)
    end
  end
end
