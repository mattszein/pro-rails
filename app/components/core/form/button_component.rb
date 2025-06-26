# frozen_string_literal: true

class Core::Form::ButtonComponent < ViewComponent::Form::ButtonComponent
  attr_accessor :theme, :size

  THEME_MAPPINGS = {
    primary: "border-primary-700 hover:bg-primary-800 focus:ring-primary-300 focus:underline dark:border-primary-500 dark:hover:bg-primary-500 dark:focus:ring-primary-800 text-primary-700 dark:text-primary-500",
    secondary: "border-secondary-600 hover:bg-secondary-600 focus:ring-secondary-300 dark:border-secondary-500 dark:hover:bg-secondary-500 dark:focus:ring-secondary-800 text-secondary-700 dark:text-secondary-500",
    create: "border-create-600 hover:border-create-500 hover:bg-create-500 focus:ring-create-300 dark:border-create-500 dark:hover:bg-create-500 dark:focus:ring-create-800 text-create-600 dark:text-create-500",
    edit: "border-edit-600 hover:border-edit-500 hover:bg-edit-500 focus:ring-edit-300 dark:border-edit-500 dark:hover:bg-edit-500 dark:focus:ring-edit-800 text-edit-600 dark:text-edit-500",
    delete: "border-delete-600 hover:border-delete-500 hover:bg-delete-500 focus:ring-delete-300 dark:border-delete-500 dark:hover:bg-delete-500 dark:focus:ring-delete-800 text-delete-600 dark:text-delete-500",
    show: "border-show-600 hover:border-show-500 hover:bg-show-500 focus:ring-show-300 dark:border-show-500 dark:hover:bg-show-500 dark:focus:ring-show-800 text-show-600 dark:text-show-500"
  }

  SIZE_MAPPINGS = {
    none: "",
    xs: "px-2 py-1.5 text-xs",
    sm: "px-3 py-2 text-sm",
    md: "px-4 py-2.5 text-base",
    lg: "px-5 py-3 text-lg",
    xlg: "px-6 py-3.5 text-2xl",
    giant: "px-8 py-5 text-4xl"
  }.freeze

  def initialize(form, value, style = {}, options = {})
    default = {theme: :primary, size: :md, fullw: false}
    style_merged = default.merge(style)
    @value = value
    @theme = style_merged[:theme]
    @fullw = style_merged[:fullw]
    @size = style_merged[:size]

    super(form, value, options)
  end

  def html_class
    class_names("border focus:ring-0 focus:outline-none focus:shadow-sm rounded-lg font-medium text-center font-semibold hover:text-white dark:hover:text-white transition-colors duration-200", THEME_MAPPINGS[@theme], SIZE_MAPPINGS[@size], @fullw ? "w-full" : "")
  end
end
