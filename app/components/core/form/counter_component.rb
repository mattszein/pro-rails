class Core::Form::CounterComponent < Core::Form::FieldComponent
  attr_accessor :theme

  THEMES = {
    primary: "bg-primary-100 dark:bg-primary-700 dark:hover:bg-primary-600 dark:border-primary-600 hover:bg-primary-200",
    secondary: "bg-secondary-100 dark:bg-secondary-700 dark:hover:bg-secondary-600 dark:border-secondary-600 hover:bg-secondary-200"
  }.freeze

  DEFAULT = {theme: :primary}.freeze

  def initialize(form, object_name, method_name, options = nil)
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    super
  end

  def html_classes
    class_names("flex-shrink-0 text-gray-900 dark:text-white border-0 bg-transparent text-sm font-normal focus:outline-none focus:ring-0 max-w-[2.5rem] text-center p-0")
  end

  def render_input
    ActionView::Helpers::Tags::NumberField.new(object_name, method_name, @view_context, options.merge({class: html_classes, data: {core__form__counter_component_target: "counter"}})).render
  end
end
