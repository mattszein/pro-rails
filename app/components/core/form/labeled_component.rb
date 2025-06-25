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
    class_names("absolute text-base text-gray-500 dark:text-gray-200 duration-300 transform -translate-y-6 scale-75 z-10 origin-[0] peer-placeholder-shown:scale-100 peer-placeholder-shown:translate-y-0 peer-focus:scale-75 group-[.is-filled]:-translate-y-4 bg-transparent", THEMES[theme], STYLE[style])
  end

  def render_label
    ActionView::Helpers::Tags::Label.new(object_name, method_name, @view_context, attribute_content, options).render
  end
end
