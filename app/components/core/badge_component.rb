class Core::BadgeComponent < ApplicationViewComponent
  option :label, default: -> {}
  option :theme, default: -> { :primary }
  option :size, default: -> { :sm }
  option :icon, default: -> {}
  option :indicator, default: -> {}
  option :classes, default: -> {}

  THEME_STYLES = {
    primary: "bg-gradient-to-r from-primary-100 to-indigo-100 text-primary-800 border border-primary-200 dark:from-primary-900/30 dark:to-indigo-900/30 dark:text-primary-200 dark:border-primary-700",
    secondary: "bg-gradient-to-r from-secondary-100 to-slate-100 text-gray-800 border border-gray-200 dark:from-secondary-800 dark:to-slate-800 dark:text-gray-200 dark:border-secondary-700",
    green: "bg-gradient-to-r from-green-100 to-emerald-100 text-green-800 border border-green-200 dark:from-green-900/30 dark:to-emerald-900/30 dark:text-green-200 dark:border-green-700",
    yellow: "bg-gradient-to-r from-yellow-100 to-amber-100 text-yellow-800 border border-yellow-200 dark:from-yellow-900/30 dark:to-amber-900/30 dark:text-yellow-200 dark:border-yellow-700",
    red: "bg-gradient-to-r from-red-100 to-pink-100 text-red-800 border border-red-200 dark:from-red-900/30 dark:to-pink-900/30 dark:text-red-200 dark:border-red-700",
    orange: "bg-gradient-to-r from-orange-100 to-amber-100 text-orange-800 border border-orange-200 dark:from-orange-900/30 dark:to-amber-900/30 dark:text-orange-200 dark:border-orange-700"
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
