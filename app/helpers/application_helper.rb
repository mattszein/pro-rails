module ApplicationHelper
  include Pagy::Frontend

  def sidebar_links
    [
      {
        label: "Home",
        path: :dashboard_path,
        icon_name: "home"
      },
      {
        label: "Settings",
        path: :dashboard_path, # Replace with actual path
        icon_name: "settings"
      },
      {
        label: "Log out",
        path: rodauth.logout_path,
        icon_name: "logout",
        options: {data: {turbo_prefetch: "false", turbo_method: "post"}, method: :post}
      }
    ]
  end

  def icon(name, options = {})
    options[:title] ||= name.underscore.humanize
    options[:aria] = true
    options[:nocomment] = true
    # options[:variant] ||= :outline
    options[:class] = options.fetch(:classes, nil)
    path = options.fetch(:path, "icons/#{name}.svg")
    icon = path
    inline_svg_tag(icon, options)
  end

  def error_tag(content, options = {})
    content_tag(:span, content, class: "block mt-1 text-red-600 text-xs dark:text-red-400", id: options[:id])
  end

  TICKET_STATUS_THEME = {open: :green, closed: :red, in_progress: :yellow}
  def ticket_status_theme(status)
    TICKET_STATUS_THEME[status.to_sym]
  end

  def form_classes
    "w-full max-w-sm space-y-4"
  end

  def accounts_columns
    [
      {
        label: "Email",
        renderer: ->(account) { account.email }
      },
      {
        label: "Actions",
        renderer: ->(account) {
          render(Core::LinkComponent.new(name: "Show", url: adminit_account_path(account), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false}}))
        }
      }
    ]
  end

  def roles_columns
    [
      {
        label: "Name",
        renderer: ->(role) { role.name }
      },
      {
        label: "Actions",
        renderer: ->(role) {
          render(Core::LinkComponent.new(name: "Show", url: adminit_role_path(role), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false}}))
        }
      }
    ]
  end

  ANNOUNCEMENT_STATUS_THEME = {draft: :yellow, scheduled: :orange, published: :green}
  def announcement_status_theme(status)
    ANNOUNCEMENT_STATUS_THEME[status.to_sym]
  end

  def announcement_columns
    [
      {
        label: "Reference",
        renderer: ->(announcement) { announcement.reference }
      },
      {
        label: "Status",
        renderer: ->(announcement) do
          render(Core::BadgeComponent.new(label: announcement.status.humanize,
            theme: announcement_status_theme(announcement.status)))
        end
      },
      {
        label: "Author",
        renderer: ->(announcement) { announcement.author.email }
      },
      {
        label: "Scheduled At",
        renderer: ->(announcement) { announcement.scheduled_at&.strftime("%Y-%m-%d %H:%M") || "-" }
      },
      {
        label: "Actions",
        renderer: ->(announcement) {
          render(Core::LinkComponent.new(name: "Show", url: adminit_announcement_path(announcement),
            style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false}}))
        }
      }
    ]
  end
end
