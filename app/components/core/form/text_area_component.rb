class Core::Form::TextAreaComponent < ViewComponent::Form::TextAreaComponent
  attr_accessor :theme

  THEMES = {
    primary: "focus:ring-primary-500 focus:border-primary-500 dark:focus:ring-primary-500 dark:focus:border-primary-500",
    secondary: "focus:ring-secondary-500 focus:border-secondary-500 dark:focus:ring-secondary-500 dark:focus:border-secondary-500"
  }.freeze

  DEFAULT = {theme: :primary}.freeze

  def initialize(form, object_name, method_name, options = {})
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    super(form, object_name, method_name, options)
  end

  def html_class
    class_names("block p-2 text-md text-gray-900 bg-transparent rounded-lg border border-gray-300 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white", THEMES[theme])
  end
end
