class Core::Form::SelectComponent < Core::Form::FieldComponent
  attr_reader :choices, :select_options

  DEFAULT_CLASS = "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"

  def initialize(form, object_name, method_name, choices, select_options, html_options)
    @choices = choices
    @select_options = select_options || {}
    super(form, object_name, method_name, html_options || {})
  end

  def html_class
    return nil if options[:multiple]

    DEFAULT_CLASS
  end

  def call
    add_tom_select_controller! if options[:multiple]
    ActionView::Helpers::Tags::Select.new(object_name, method_name, @view_context, choices, select_options, options).render
  end

  private

  def add_tom_select_controller!
    return if options.dig(:data, :controller) || options[:"data-controller"] || options["data-controller"]

    options[:data] ||= {}
    options[:data][:controller] = "core--form--select-component"
  end
end
