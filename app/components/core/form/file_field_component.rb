# app/components/core/form/file_field_component.rb
class Core::Form::FileFieldComponent < ViewComponent::Form::FieldComponent
  CUSTOM_OPTIONS_DEFAULTS = {
    label: nil,
    helper_text: nil,
    icon_name: nil
  }.freeze
  attr_reader(*CUSTOM_OPTIONS_DEFAULTS.keys)

  def initialize(form, object_name, method_name, options = {})
    CUSTOM_OPTIONS_DEFAULTS.each do |key, default|
      instance_variable_set(:"@#{key}", options.fetch(key, default))
    end
    @merged_options = CUSTOM_OPTIONS_DEFAULTS.merge(options)
    super(form, object_name, method_name, @merged_options)
  end

  private

  def display_label_text
    @label || method_name.to_s.humanize
  end

  def input_options
    @options.merge(
      class: input_classes
    )
  end

  def input_classes
    "block w-full text-sm text-slate-600 file:mr-4 file:py-2.5 file:px-5 file:rounded-full file:border-0 file:text-sm file:font-medium file:bg-slate-800 file:text-white hover:file:bg-slate-900 file:cursor-pointer file:transition-all file:duration-200 cursor-pointer border border-slate-300 rounded-full bg-white p-3 hover:border-slate-400 transition-colors focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2"
  end

  def input_tag
    ActionView::Helpers::Tags::FileField.new(object_name, method_name, @view_context, input_options).render
  end

  def icon_tag
    return nil unless icon_name
    @view_context.helpers.icon(icon_name, classes: "w-5 h-5 text-indigo-500")
  end
end
