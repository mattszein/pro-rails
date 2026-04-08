module Core::Form::InputClasses
  attr_accessor :theme, :size
  THEMES = {
    primary: "focus:ring-primary-400 dark:focus:ring-primary-400",
    secondary: "focus:ring-secondary-400 dark:focus:ring-secondary-400"
  }.freeze

  SIZES = {
    sm: "pb-3 pt-3 text-sm",
    md: "pb-3 pt-3 text-base"
  }.freeze

  DEFAULT = {theme: :primary, size: :md}.freeze

  def initialize(form, object_name, method_name, options = nil)
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    @size = options_merged[:size]
    super
  end

  def html_class
    class_names("block p-3 w-full text-gray-600 bg-default rounded border border-gray-200 appearance-none dark:text-white dark:border-gray-600 focus:outline-none focus:ring-2 transition-all duration-200 focus:border-transparent placeholder:text-gray-500 dark:placeholder:text-gray-300", THEMES[theme])
  end
end
