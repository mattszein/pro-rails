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
    base_classes = "inline-flex p-3 hover:cursor-pointer hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg w-full transition duration-200 group"
    active_classes = active? ? "bg-blue-100 dark:bg-blue-900" : ""

    class_names(base_classes, active_classes)
  end

  def icon_classes
    base_classes = "h-8 text-gray-500 dark:text-gray-100 group-hover:text-gray-900 dark:group-hover:text-blue-500 transition duration-200"
    active_classes = active? ? "text-blue-600 dark:text-blue-400" : ""

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
