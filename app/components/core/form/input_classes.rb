module Core::Form::InputClasses
  attr_accessor :theme, :size
  THEMES = {
    primary: "focus:border-primary-600 dark:focus:border-primary-500",
    secondary: "focus:border-secondary-600 dark:focus:border-secondary-500"
  }.freeze

  SIZES = {
    sm: "pb-1 pt-3 text-sm",
    md: "pb-2 pt-3 group-[.is-floating]:pb-2 group-[.is-floating]:pt-7 text-base"
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
    class_names("block px-2.5 pb-2.5 pt-4 w-full text-sm text-gray-900 bg-transparent rounded-lg border-1 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-blue-500 focus:outline-none focus:ring-0 focus:border-blue-600 peer group-[.is-filled]:bg-gray-50 dark:group-[.is-filled]:bg-gray-800 group-[.is-filled]:px-3.5 w-full", THEMES[theme])
  end
end
