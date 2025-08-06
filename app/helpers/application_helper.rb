module ApplicationHelper
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
end
