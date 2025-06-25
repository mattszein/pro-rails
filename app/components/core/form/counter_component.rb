class Core::Form::CounterComponent < ViewComponent::Form::FieldComponent
  attr_accessor :theme

  THEMES = {
    primary: "bg-gray-100 dark:bg-gray-700 dark:hover:bg-gray-600 dark:border-gray-600 hover:bg-gray-200",
    secondary: "bg-gray-100 dark:bg-gray-700 dark:hover:bg-gray-600 dark:border-gray-600 hover:bg-gray-200"
  }.freeze

  DEFAULT = {theme: :primary}.freeze

  def initialize(form, object_name, method_name, options = nil)
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    super(form, object_name, method_name, options)
  end

  def html_classes
    class_names("flex-shrink-0 text-gray-900 dark:text-white border-0 bg-transparent text-sm font-normal focus:outline-none focus:ring-0 max-w-[2.5rem] text-center p-0")
  end

  def render_input
    ActionView::Helpers::Tags::NumberField.new(object_name, method_name, @view_context, options.merge({class: html_classes, data: {core__form__counter_component_target: "counter"}})).render
  end
end
