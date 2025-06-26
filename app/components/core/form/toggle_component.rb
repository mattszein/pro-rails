class Core::Form::ToggleComponent < ViewComponent::Form::CheckBoxComponent
  attr_accessor :theme, :size

  THEMES = {
    primary: "peer-focus:ring-primary-300 dark:peer-focus:ring-primary-800 peer-checked:bg-primary-600",
    secondary: "peer-focus:ring-secondary-300 dark:peer-focus:ring-secondary-800 peer-checked:bg-secondary-600"
  }.freeze

  SIZES = {
    sm: "w-9 h-5 after:h-4 after:w-4",
    md: "w-11 h-6 after:h-5 after:w-5",
    lg: "w-14 h-7 after:h-6 after:w-6"
  }.freeze

  DEFAULT = {theme: :primary, size: :md}.freeze

  def initialize(form, object_name, method_name, checked_value, unchecked_value, options = {}) # rubocop:disable Metrics/ParameterLists
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    @size = options_merged[:size]
    super
  end

  def html_class
    class_names("sr-only peer")
  end

  def classes
    class_names(THEMES[theme], SIZES[size])
  end

  def render_checkbox
    ActionView::Helpers::Tags::CheckBox.new(
      object_name,
      method_name,
      @view_context,
      checked_value,
      unchecked_value,
      options
    ).render
  end
end
