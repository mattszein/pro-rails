class Core::SidebarLinkComponent < ApplicationViewComponent
  include Rails.application.routes.url_helpers

  option :label
  option :path
  option :icon_name
  option :active_paths, default: -> { [] }
  option :html_options, default: -> { {} }
  option :animated_type, default: -> {}

  ICON_STYLES = {
    true => "text-secondary-500 dark:text-secondary-500",
    false => ""
  }.freeze

  SPAN_STYLES = {
    true => "text-primary-500 dark:text-primary-400 border-b-2 border-secondary-400",
    false => "text-gray-600 dark:text-white"
  }.freeze

  ANIMATED_ICON_ACTION = "mouseenter->animated-icon#start mouseleave->animated-icon#stop focusin->animated-icon#start focusout->animated-icon#stop"

  def link_classes
    "flex gap-2 items-center p-3 hover:cursor-pointer rounded-sm w-full group/link focus:outline-none"
  end

  def icon_classes
    class_names("h-8 text-gray-500 dark:text-gray-400 group-hover/link:text-secondary-500 dark:group-hover/link:text-secondary-500 group-focus/link:text-secondary-500 dark:group-focus/link:text-secondary-500", ICON_STYLES[active?])
  end

  def span_classes
    class_names("opacity-100 ml-2 text-lg group-hover/drawer:opacity-100 group-hover/drawer:transition-opacity group-hover/link:text-primary-500 dark:group-hover/link:text-primary-500 outline-none group-focus/link:text-primary-500 dark:group-focus/link:text-primary-500", SPAN_STYLES[active?])
  end

  def link_html_options
    merged = {class: link_classes}.deep_merge(html_options)
    return merged unless animated_type

    existing_data = merged[:data] || {}
    merged[:data] = existing_data.merge(
      controller: join_tokens(existing_data[:controller], "animated-icon"),
      animated_icon_type_value: animated_type,
      action: join_tokens(existing_data[:action], ANIMATED_ICON_ACTION)
    )
    merged
  end

  private

  def join_tokens(existing, added)
    [existing, added].compact.reject(&:empty?).join(" ")
  end

  def active?
    return false if active_paths.empty?

    current_path = request.path
    active_paths.any? { |active_path| current_path == active_path }
  end
end
