# app/helpers/custom_form_builder.rb
class CustomFormBuilder < ViewComponent::Form::Builder
  # Set the namespace you want to use for your own components
  namespace "Core"

  def button(value = "", style = {theme: :primary, size: :md, fullw: false}, options = {}, &block)
    render_component("form::Button", value, style, options, &block)
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    render_component("form::CheckBox", @object_name, method, checked_value, unchecked_value, objectify_options(options))
  end

  def code(method, length = 6, options = {})
    render_component("form::Code", @object_name, method, length)
  end

  def labeled(method, text = nil, options = {}, &block)
    render_component("form::Labeled", @object_name, method, text, objectify_options(options), &block)
  end

  def number_field(method, options = {})
    render_component("form::MaterialInput", @object_name, method, objectify_options(options.merge(input_type: :number)))
  end

  def password_field(method, options = {})
    render_component("form::MaterialInput", @object_name, method, objectify_options(options.merge(input_type: :password)))
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    default_classes = "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
    html_options[:class] = [default_classes, html_options[:class]].compact.join(" ")
    super
  end

  def multi_select(method, choices = nil, options = {}, html_options = {}, &block)
    html_options[:multiple] = true
    original_select = ActionView::Helpers::FormBuilder.instance_method(:select)
    original_select.bind_call(self, method, choices, options, html_options, &block)
  end

  def text_area(method, options = {})
    render_component("form::TextArea", @object_name, method, objectify_options(options))
  end

  def text_field(method, options = {})
    render_component("form::MaterialInput", @object_name, method, objectify_options(options.merge(input_type: :text)))
  end

  def toggle(method, options = {}, checked_value = "1", unchecked_value = "0")
    render_component("form::Toggle", @object_name, method, checked_value, unchecked_value, objectify_options(options))
  end

  def counter(method, options = {})
    render_component("form::Counter", @object_name, method, objectify_options(options))
  end

  def file_field(method, options = {})
    render_component("form::FileField", @object_name, method, objectify_options(options))
  end

  def date_time(method, options = {})
    render_component("form::DateTime", @object_name, method, objectify_options(options))
  end
end
