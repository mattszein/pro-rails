class Core::BadgeComponent < ViewComponent::Base
  attr_reader :theme, :label

  THEMES = {
    primary: "bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300",
    secondary: "bg-secondary-100 text-secondary-800 dark:bg-secondary-900 dark:text-secondary-300",
    green: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300",
    yellow: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300",
    red: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
  }.freeze

  SIZE = {
    xs: "text-xs me-2 px-2.5 py-0.5",
    sm: "text-sm me-2 px-2.5 py-0.5",
    md: "text-md me-2 px-2.5 py-0.5",
    lg: "text-lg me-2 px-2.5 py-0.5"
  }

  DEFAULT = {theme: :primary, size: :sm}.freeze

  def initialize(label = nil, options: {})
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    @size = options_merged[:size]
    @classes = options[:class]
    @label = label
  end

  def html_class
    class_names("rounded-full capitalize", THEMES[@theme], SIZE[@size], @classes)
  end
end
