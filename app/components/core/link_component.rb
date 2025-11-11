class Core::LinkComponent < ViewComponent::Base
  include ActionView::Helpers::UrlHelper
  attr_accessor :style, :theme, :size, :name, :url, :options

  STYLE = {default: :default,
           as_button: :as_button,
           no_style: :no_style}.freeze
  DEFAULT = {style: :as_button, theme: :primary, size: :md}.freeze

  def initialize(name: nil, url: nil, options: {}, &block)
    custom_style = options&.delete(:custom_style) || {}
    style_merged = DEFAULT.merge(custom_style)
    @style = style_merged[:style]
    @theme = style_merged[:theme]
    @size = style_merged[:size]
    @name = name
    @url = url
    @fullw = style_merged[:fullw]
    @options = options
  end

  def html_class
    case style
    when :as_button
      Core::Form::ButtonComponent.new(nil, nil, {theme: theme, size: size, fullw: @fullw}).html_class
    when :default
      "inline-flex items-center justify-center border border-transparent rounded-md font-medium focus:outline-none dark:text-gray-100 hover:font-bold hover:underline"
    end
  end

  def render_content
    if content
      link_to(url, options) do
        content
      end
    else
      link_to(name, url, options.merge({class: [options[:class], html_class].compact.join(" ")}))
    end
  end

  erb_template <<~ERB
    <%= render_content %>
  ERB
end
