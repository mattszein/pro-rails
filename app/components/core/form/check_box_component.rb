class Core::Form::CheckBoxComponent < Core::Form::FieldComponent
  attr_reader :checked_value, :unchecked_value

  def initialize(form, object_name, method_name, checked_value = "1", unchecked_value = "0", options = {})
    @checked_value = checked_value
    @unchecked_value = unchecked_value
    super(form, object_name, method_name, options)
  end

  def html_class
    "w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 rounded focus:ring-purple-500 dark:focus:ring-purple-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600 cursor-pointer"
  end

  def call
    ActionView::Helpers::Tags::CheckBox.new(object_name, method_name, @view_context, checked_value, unchecked_value, options).render
  end
end
