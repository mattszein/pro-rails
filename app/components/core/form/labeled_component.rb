class Core::Form::LabeledComponent < ViewComponent::Form::LabelComponent
  attr_accessor :theme, :style

  THEMES = {
    primary: "peer-focus:text-primary-700 peer-focus:dark:text-primary-600",
    secondary: "peer-focus:text-secondary-600 peer-focus:dark:text-secondary-500"
  }.freeze

  STYLE = {
    default: "top-7 peer-focus:-translate-y-6",
    filled: "top-5 left-3.5 peer-focus:-translate-y-4"
  }.freeze

  DEFAULT = {theme: :primary, style: :default}.freeze

  def initialize(form, object_name, method_name, content_or_options = nil, options = nil)
    custom_style = options&.delete(:custom_style) || {}
    options_merged = DEFAULT.merge(custom_style)
    @theme = options_merged[:theme]
    @style = options_merged[:style]
    super
  end

  def html_class
    class_names("absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-4 scale-75 top-2 z-10 origin-[0] bg-default dark:bg-default px-2 peer-focus:px-2 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 peer-focus:top-2 peer-focus:scale-75 peer-focus:-translate-y-4 rtl:peer-focus:translate-x-1/4 rtl:peer-focus:left-auto start-1", THEMES[theme])
  end

  def render_label
    ActionView::Helpers::Tags::Label.new(object_name, method_name, @view_context, attribute_content, options).render
  end
end
