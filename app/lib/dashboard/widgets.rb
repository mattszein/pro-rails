module Dashboard
  # Declares every dashboard widget. Lives in the autoload path (not an
  # initializer) so edits are picked up by code reloading in development:
  # the `to_prepare` hook in config/initializers/dashboard_widgets.rb calls
  # `install` again with the reloaded class.
  module Widgets
    module_function

    def install
      WidgetRegistry.clear

      # Rendered inline (not via a lazy turbo-frame): TomSelect must initialize in
      # the page's normal Turbo-visit lifecycle. Inside a lazy frame the Stimulus
      # controller does not reliably connect, so the select never becomes a
      # TomSelect. This widget has no expensive data to defer, so eager render is free.
      WidgetRegistry.register(
        key: :accounts_general, resource: :account, kind: :general,
        policy_class: "Adminit::AccountPolicy",
        component_class: "Adminit::Dashboard::Accounts::GeneralWidgetComponent",
        lazy: false
      )

      WidgetRegistry.register(
        key: :accounts_analytics, resource: :account, kind: :analytics,
        policy_class: "Adminit::AccountPolicy",
        component_class: "Adminit::Dashboard::Accounts::AnalyticsWidgetComponent",
        refresh_interval: 120
      )

      WidgetRegistry.register(
        key: :roles_general, resource: :role, kind: :general, span: :half,
        policy_class: "Adminit::RolePolicy",
        component_class: "Adminit::Dashboard::Roles::GeneralWidgetComponent"
      )

      WidgetRegistry.register(
        key: :announcements_general, resource: :announcement, kind: :general,
        policy_class: "Adminit::AnnouncementPolicy",
        component_class: "Adminit::Dashboard::Announcements::GeneralWidgetComponent"
      )

      WidgetRegistry.register(
        key: :tickets_personal, resource: :ticket, kind: :personal,
        policy_class: "Adminit::TicketPolicy",
        component_class: "Adminit::Dashboard::Tickets::PersonalWidgetComponent",
        refresh_interval: 30
      )

      WidgetRegistry.register(
        key: :tickets_general, resource: :ticket, kind: :general,
        policy_class: "Adminit::TicketPolicy",
        component_class: "Adminit::Dashboard::Tickets::GeneralWidgetComponent",
        refresh_interval: 30
      )

      WidgetRegistry.register(
        key: :tickets_analytics, resource: :ticket, kind: :analytics,
        policy_class: "Adminit::TicketPolicy",
        component_class: "Adminit::Dashboard::Tickets::AnalyticsWidgetComponent",
        refresh_interval: 60
      )

      # pro_rails:dashboard_widget_generator — generated registrations are inserted above (do not remove)
    end
  end
end
