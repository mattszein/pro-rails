Rails.application.config.to_prepare do
  Dashboard::WidgetRegistry.clear

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
    key: :permissions_overview, resource: :permission, kind: :general,
    policy_class: "Adminit::PermissionPolicy",
    component_class: "Adminit::Dashboard::Permissions::OverviewWidgetComponent",
    turbo_frame_id: "dashboard_permissions_overview"
  )
end
