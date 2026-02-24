# app/components/core/form/material_input_component.rb
class Core::Form::MaterialInputComponent < Core::Form::FieldComponent
  attr_reader :variant, :theme, :input_type, :placeholder_text, :background_color

  VARIANTS = {
    filled: {
      container: "relative",
      input: "block rounded-t-lg px-2.5 pb-2.5 pt-5 w-full text-sm text-gray-900 bg-highlight border-0 border-b-2 border-gray-300 appearance-none dark:text-white dark:border-gray-600 focus:outline-none focus:ring-0 peer",
      label: "absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-4 scale-75 top-4 z-10 origin-[0] start-2.5 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-4 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto"
    },
    outlined: {
      container: "relative",
      input: "block px-2.5 pb-2.5 pt-4 w-full text-sm text-gray-900 bg-transparent rounded-lg border-1 border-gray-300 appearance-none dark:text-white dark:border-gray-600 focus:outline-none focus:ring-0 peer",
      label: "absolute text-md font-bold text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-4 scale-75 top-2 z-10 origin-[0] px-2 peer-focus:px-2 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 peer-placeholder-shown:bg-transparent peer-focus:top-2 peer-focus:scale-75 peer-focus:-translate-y-4 peer-valid:top-2 peer-valid:scale-75 peer-valid:-translate-y-4 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto start-1"
    },
    standard: {
      container: "relative z-0",
      input: "block py-2.5 px-0 w-full text-sm text-gray-900 bg-transparent border-0 border-b-2 border-gray-300 appearance-none dark:text-white dark:border-gray-600 focus:outline-none focus:ring-0 peer",
      label: "absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-9 scale-75 top-3 -z-10 origin-[0] peer-focus:start-0 peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 peer-focus:-translate-y-6 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto"
    }
  }.freeze

  THEMES = {
    primary: {
      input: "dark:focus:border-primary-500 focus:border-primary-600",
      label: "peer-focus:text-primary-600 peer-focus:dark:text-primary-500"
    },
    secondary: {
      input: "dark:focus:border-secondary-500 focus:border-secondary-600",
      label: "peer-focus:text-secondary-600 peer-focus:dark:text-secondary-500"
    },
    success: {
      input: "dark:focus:border-green-500 focus:border-green-600",
      label: "peer-focus:text-green-600 peer-focus:dark:text-green-500"
    },
    danger: {
      input: "dark:focus:border-red-500 focus:border-red-600",
      label: "peer-focus:text-red-600 peer-focus:dark:text-red-500"
    }
  }.freeze

  DEFAULT_OPTIONS = {
    variant: :outlined,
    theme: :primary,
    input_type: :text,
    placeholder_text: " ", # Required for floating labels
    background_color: nil # Will use default if not specified
  }.freeze

  def initialize(form, object_name, method_name, options = {})
    @options = DEFAULT_OPTIONS.merge(options.except(:variant, :theme, :input_type, :placeholder_text, :background_color))
    @variant = options.fetch(:variant, DEFAULT_OPTIONS[:variant])
    @theme = options.fetch(:theme, DEFAULT_OPTIONS[:theme])
    @input_type = options.fetch(:input_type, DEFAULT_OPTIONS[:input_type])
    @placeholder_text = options.fetch(:placeholder_text, DEFAULT_OPTIONS[:placeholder_text])
    @background_color = options.fetch(:background_color, DEFAULT_OPTIONS[:background_color])

    super(form, object_name, method_name, @options)
  end

  private

  def container_classes
    VARIANTS.dig(variant, :container) || ""
  end

  def input_classes
    base_classes = VARIANTS.dig(variant, :input) || ""
    theme_classes = THEMES.dig(theme, :input) || ""
    class_names(base_classes, theme_classes)
  end

  def label_classes
    base_classes = VARIANTS.dig(variant, :label) || ""
    theme_classes = THEMES.dig(theme, :label) || ""
    background_classes = background_color_classes
    class_names(base_classes, theme_classes, background_classes)
  end

  def input_options
    @options.merge(
      class: input_classes,
      placeholder: placeholder_text,
      id: field_id
    )
  end

  def field_id
    @field_id ||= "#{object_name}_#{method_name}_#{SecureRandom.hex(4)}"
  end

  def label_text
    @options[:label] || method_name.to_s.humanize
  end

  def background_color_classes
    return "" unless variant == :outlined

    if background_color
      "peer-focus:#{background_color} peer-valid:#{background_color}"
    else
      # Use bg-highlight which automatically handles light/dark mode
      "peer-focus:bg-highlight peer-valid:bg-highlight"
    end
  end

  def input_tag
    # Use ActionView::Helpers::Tags directly to avoid circular dependency
    case input_type
    when :text
      ActionView::Helpers::Tags::TextField.new(object_name, method_name, @view_context, input_options).render
    when :email
      ActionView::Helpers::Tags::EmailField.new(object_name, method_name, @view_context, input_options).render
    when :password
      ActionView::Helpers::Tags::PasswordField.new(object_name, method_name, @view_context, input_options).render
    when :number
      ActionView::Helpers::Tags::NumberField.new(object_name, method_name, @view_context, input_options).render
    when :tel
      ActionView::Helpers::Tags::TelField.new(object_name, method_name, @view_context, input_options).render
    when :url
      ActionView::Helpers::Tags::UrlField.new(object_name, method_name, @view_context, input_options).render
    when :search
      ActionView::Helpers::Tags::SearchField.new(object_name, method_name, @view_context, input_options).render
    else
      ActionView::Helpers::Tags::TextField.new(object_name, method_name, @view_context, input_options).render
    end
  end
end
