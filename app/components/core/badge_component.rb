class Core::BadgeComponent < ViewComponent::Base
  attr_reader :theme, :label, :icon, :indicator

  THEMES = {
    primary: "bg-gradient-to-r from-primary-100 to-indigo-100 text-primary-800 border border-primary-200 dark:from-primary-900/30 dark:to-indigo-900/30 dark:text-primary-200 dark:border-primary-700",
    secondary: "bg-gradient-to-r from-secondary-100 to-slate-100 text-gray-800 border border-gray-200 dark:from-secondary-800 dark:to-slate-800 dark:text-gray-200 dark:border-secondary-700",
    green: "bg-gradient-to-r from-green-100 to-emerald-100 text-green-800 border border-green-200 dark:from-green-900/30 dark:to-emerald-900/30 dark:text-green-200 dark:border-green-700",
    yellow: "bg-gradient-to-r from-yellow-100 to-amber-100 text-yellow-800 border border-yellow-200 dark:from-yellow-900/30 dark:to-amber-900/30 dark:text-yellow-200 dark:border-yellow-700",
    red: "bg-gradient-to-r from-red-100 to-pink-100 text-red-800 border border-red-200 dark:from-red-900/30 dark:to-pink-900/30 dark:text-red-200 dark:border-red-700",
    orange: "bg-gradient-to-r from-orange-100 to-amber-100 text-orange-800 border border-orange-200 dark:from-orange-900/30 dark:to-amber-900/30 dark:text-orange-200 dark:border-orange-700"
  }.freeze

  INDICATOR_COLOR = {
    primary: "bg-primary-500",
    secondary: "bg-secondary-500",
    green: "bg-green-500",
    yellow: "bg-yellow-500",
    red: "bg-red-500",
    orange: "bg-orange-500"
  }

  SIZE = {
    xs: "text-xs me-2 px-2.5 py-0.5",
    sm: "text-sm me-2 px-2.5 py-0.5",
    md: "text-md me-2 px-2.5 py-0.5",
    lg: "text-lg me-2 px-2.5 py-0.5"
  }

  DEFAULT = {theme: :primary, size: :sm, icon: nil}.freeze

  def initialize(label = nil, options: {})
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    @size = options_merged[:size]
    @icon = options_merged[:icon]
    @indicator = options_merged[:indicator]
    @classes = options[:class]
    @label = label
  end

  def html_class
    class_names("inline-flex items-center rounded-full capitalize", THEMES[@theme], SIZE[@size], @classes)
  end
end
