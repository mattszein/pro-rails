module ApplicationHelper
  def sidebar_links
    [
      {
        label: I18n.t("shared.navigation.home"),
        path: :dashboard_path,
        icon_name: "home"
      },
      {
        label: I18n.t("shared.navigation.settings"),
        path: :dashboard_path, # Replace with actual path
        icon_name: "settings"
      },
      {
        label: I18n.t("shared.common.logout"),
        path: rodauth.logout_path,
        icon_name: "logout",
        options: {data: {turbo_prefetch: "false", turbo_method: "post"}, method: :post}
      }
    ]
  end

  def icon(name, options = {})
    animated_type = options.delete(:animated_type)
    options[:title] ||= name.underscore.humanize
    options[:aria] = true
    options[:nocomment] = true
    # options[:variant] ||= :outline
    options[:class] = options.fetch(:classes, nil)
    path = options.fetch(:path, "icons/#{name}.svg")
    svg = inline_svg_tag(path, options)

    if animated_type
      content_tag(:div, svg,
        data: {
          controller: "animated-icon",
          animated_icon_type_value: animated_type
        })
    else
      svg
    end
  end

  def error_tag(content, options = {})
    content_tag(:span, content, class: "block mt-1 text-red-600 text-xs dark:text-red-400", id: options[:id])
  end

  TICKET_STATUS_THEME = {
    open: :green,
    in_progress: :yellow,
    finished: :red,
    reopen_requested: :orange,
    reopened: :green,
    closed: :red
  }
  def ticket_status_theme(status)
    TICKET_STATUS_THEME[status.to_sym]
  end

  def form_classes
    "w-full max-w-sm space-y-4"
  end

  ACCOUNT_STATUS_THEME = {unverified: :yellow, verified: :green, closed: :red}.freeze

  def account_status_theme(status)
    ACCOUNT_STATUS_THEME[status.to_sym]
  end

  ANNOUNCEMENT_STATUS_THEME = {draft: :yellow, scheduled: :orange, published: :green}
  def announcement_status_theme(status)
    ANNOUNCEMENT_STATUS_THEME[status.to_sym]
  end
end
