class Core::BadgeComponent < ApplicationViewComponent
  option :label, default: -> {}
  option :theme, default: -> { :primary }
  option :size, default: -> { :sm }
  option :icon, default: -> {}
  option :indicator, default: -> {}
  option :classes, default: -> {}

  THEME_STYLES = {
    primary: "bg-primary-300 text-primary-800 border border-primary-200 dark:bg-primary-700 dark:text-primary-200 dark:border-primary-700",
    secondary: "bg-secondary-300 text-gray-800 border border-gray-200 dark:bg-secondary-700 dark:text-gray-200 dark:border-secondary-700",
    green: "bg-green-300 text-green-800 border border-green-200 dark:bg-green-900/30 dark:text-green-200 dark:border-green-700",
    yellow: "bg-yellow-300 text-yellow-800 border border-yellow-200 dark:bg-yellow-900/30 dark:text-yellow-200 dark:border-yellow-700",
    red: "bg-red-300 text-red-800 border border-red-200 dark:bg-red-900/30 dark:text-red-200 dark:border-red-700",
    orange: "bg-orange-300 text-orange-800 border border-orange-200 dark:bg-orange-900/30 dark:text-orange-200 dark:border-orange-700"
  }.freeze

  SIZE_STYLES = {
    xs: "text-xs me-2 px-2.5 py-0.5",
    sm: "text-sm me-2 px-2.5 py-0.5",
    md: "text-md me-2 px-2.5 py-0.5",
    lg: "text-lg me-2 px-2.5 py-0.5"
  }.freeze

  INDICATOR_STYLES = {
    primary: "bg-primary-500",
    secondary: "bg-secondary-500",
    green: "bg-green-500",
    yellow: "bg-yellow-500",
    red: "bg-red-500",
    orange: "bg-orange-500"
  }.freeze

  def html_class
    class_names("inline-flex items-center rounded-full capitalize", THEME_STYLES[theme], SIZE_STYLES[size], classes)
  end

  def indicator_class
    class_names("w-2 h-2 rounded-full mr-2", INDICATOR_STYLES[theme])
  end
end
