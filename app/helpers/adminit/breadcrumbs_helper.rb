module Adminit::BreadcrumbsHelper
  # controller_name => [navigation i18n key, path helper]
  RESOURCE_MAP = {
    "accounts" => [:accounts, :adminit_accounts_path],
    "announcements" => [:announcements, :adminit_announcements_path],
    "tickets" => [:tickets, :adminit_tickets_path],
    "roles" => [:roles, :adminit_roles_path],
    "permissions" => [:permissions, :adminit_permissions_path]
  }.freeze

  # Only read views get a trail. Everything else (mutations, modal/frame
  # content) is excluded so breadcrumbs never appear inside a modal.
  BREADCRUMB_ACTIONS = %w[index show].freeze

  def adminit_breadcrumb_trail
    crumb = Adminit::BreadcrumbComponent::Crumb
    trail = [crumb.new(label: t("adminit.navigation.dash"), path: adminit_root_path, icon: "home")]

    controller = controller_name # already the last segment, e.g. "tickets"
    resource = RESOURCE_MAP[controller]
    return trail unless resource
    return trail unless BREADCRUMB_ACTIONS.include?(action_name)

    nav_key, path_helper = resource
    trail << crumb.new(label: t("adminit.navigation.#{nav_key}"), path: public_send(path_helper))

    if action_name == "show"
      record = instance_variable_get("@#{controller.singularize}")
      if record
        label = record.respond_to?(:breadcrumb_title) ? record.breadcrumb_title : "##{record.id}"
        trail << crumb.new(label: label, path: nil) # current page, unlinked
      end
    end

    trail
  end
end
