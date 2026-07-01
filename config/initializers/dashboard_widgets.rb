Rails.application.config.to_prepare do
  Dashboard::WidgetRegistry.clear

  Dashboard::WidgetRegistry.register(
    key: :accounts_general, resource: :account, kind: :general,
    policy_class: "Adminit::AccountPolicy",
    component_class: "Adminit::Dashboard::Accounts::GeneralWidgetComponent",
    turbo_frame_id: "dashboard_accounts_general",
    # Rendered inline (not via a lazy turbo-frame): TomSelect must initialize in
    # the page's normal Turbo-visit lifecycle. Inside a lazy frame the Stimulus
    # controller does not reliably connect, so the select never becomes a
    # TomSelect. This widget has no expensive data to defer, so eager render is free.
    lazy: false
  )

  Dashboard::WidgetRegistry.register(
    key: :accounts_analytics, resource: :account, kind: :analytics,
    policy_class: "Adminit::AccountPolicy",
    component_class: "Adminit::Dashboard::Accounts::AnalyticsWidgetComponent",
    turbo_frame_id: "dashboard_accounts_analytics",
    refresh_interval: 120
  )

  Dashboard::WidgetRegistry.register(
    key: :permissions_overview, resource: :permission, kind: :general, span: :half,
    policy_class: "Adminit::PermissionPolicy",
    component_class: "Adminit::Dashboard::Permissions::OverviewWidgetComponent",
    turbo_frame_id: "dashboard_permissions_overview"
  )

  Dashboard::WidgetRegistry.register(
    key: :roles_general, resource: :role, kind: :general, span: :half,
    policy_class: "Adminit::RolePolicy",
    component_class: "Adminit::Dashboard::Roles::GeneralWidgetComponent",
    turbo_frame_id: "dashboard_roles_general"
  )

  Dashboard::WidgetRegistry.register(
    key: :announcements_general, resource: :announcement, kind: :general,
    policy_class: "Adminit::AnnouncementPolicy",
    component_class: "Adminit::Dashboard::Announcements::GeneralWidgetComponent",
    turbo_frame_id: "dashboard_announcements_general"
  )

  Dashboard::WidgetRegistry.register(
    key: :announcements_analytics, resource: :announcement, kind: :analytics,
    policy_class: "Adminit::AnnouncementPolicy",
    component_class: "Adminit::Dashboard::Announcements::AnalyticsWidgetComponent",
    turbo_frame_id: "dashboard_announcements_analytics",
    refresh_interval: 120
  )

  Dashboard::WidgetRegistry.register(
    key: :tickets_personal, resource: :ticket, kind: :personal,
    policy_class: "Adminit::TicketPolicy",
    component_class: "Adminit::Dashboard::Tickets::PersonalWidgetComponent",
    turbo_frame_id: "dashboard_tickets_personal",
    refresh_interval: 30
  )

  Dashboard::WidgetRegistry.register(
    key: :tickets_general, resource: :ticket, kind: :general,
    policy_class: "Adminit::TicketPolicy",
    component_class: "Adminit::Dashboard::Tickets::GeneralWidgetComponent",
    turbo_frame_id: "dashboard_tickets_general",
    refresh_interval: 30
  )

  Dashboard::WidgetRegistry.register(
    key: :tickets_analytics, resource: :ticket, kind: :analytics,
    policy_class: "Adminit::TicketPolicy",
    component_class: "Adminit::Dashboard::Tickets::AnalyticsWidgetComponent",
    turbo_frame_id: "dashboard_tickets_analytics",
    refresh_interval: 60
  )
end
