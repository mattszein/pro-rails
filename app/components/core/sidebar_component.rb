class Core::SidebarComponent < ViewComponent::Base
  attr_reader :open, :navigation_items

  def initialize(open: false, navigation_items: nil)
    @open = open
    @navigation_items = navigation_items || []
  end

  private

  def sidebar_classes
    base_classes = "fixed top-16 right-0 z-30 w-20 h-screen border-l border-gray-200 transition-transform bg-white border-r border-gray-200 translate-x-0 dark:bg-gray-800 dark:border-gray-700"
    visibility_class = open ? "" : "hidden"
    transition_classes = "-translate-x-full"

    class_names(base_classes, visibility_class, transition_classes)
  end
end
