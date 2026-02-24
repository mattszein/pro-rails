class Core::SidebarLinkComponent < ViewComponent::Base
  attr_reader :label, :path, :icon_name, :active_paths, :options
  include Rails.application.routes.url_helpers

  def initialize(label:, path:, icon_name:, active_paths: [], options: {})
    @label = label
    @path = path
    @icon_name = icon_name
    @active_paths = active_paths
    @options = options
  end

  def link_classes
    "flex gap-2 items-center p-3 hover:cursor-pointer rounded-sm w-full group/link"
  end

  def icon_classes
    base_classes = "h-8 text-gray-500 dark:text-gray-400 group-hover/link:text-secondary-500 dark:group-hover/link:text-secondary-500"
    active_classes = active? ? "text-secondary-500 dark:text-secondary-500" : ""

    class_names(base_classes, active_classes)
  end

  def span_classes
    base_classes = "opacity-100 ml-2 text-lg group-hover/drawer:opacity-100 group-hover/drawer:transition-opacity group-hover/link:text-primary-500 dark:group-hover/link:text-primary-500"
    active_classes = active? ? "text-primary-500 dark:text-primary-400 border-b-2 border-secondary-400" : "text-gray-600 dark:text-white"

    class_names(base_classes, active_classes)
  end

  def link_options
    default_options = {
      class: link_classes,
      custom_style: {style: :no_style}
    }

    default_options.deep_merge(options)
  end

  private

  def active?
    return false if active_paths.empty?

    current_path = request.path
    active_paths.any? { |active_path| current_path == active_path }
  end
end
