class Core::LinkComponent < ApplicationViewComponent
  include ActionView::Helpers::UrlHelper

  option :name, default: -> {}
  option :url, default: -> {}
  option :style, default: -> { :as_button }
  option :theme, default: -> { :primary }
  option :size, default: -> { :md }
  option :fullw, default: -> {}
  option :html_options, default: -> { {} }

  STYLE_TYPES = {default: :default, as_button: :as_button, no_style: :no_style}.freeze

  def html_class
    case style
    when :as_button
      Core::Form::ButtonComponent.new(nil, nil, {theme: theme, size: size, fullw: fullw}).html_class
    when :default
      "inline-flex items-center justify-center border border-transparent rounded-md font-medium focus:outline-none dark:text-gray-100 hover:font-bold hover:underline"
    end
  end

  def render_content
    if content
      link_to(url, html_options) do
        content
      end
    else
      link_to(name, url, html_options.merge({class: [html_options[:class], html_class].compact.join(" ")}))
    end
  end

  erb_template <<~ERB
    <%= render_content %>
  ERB
end
