class Core::Form::CheckBoxComponent < ViewComponent::Form::CheckBoxComponent
  def html_class
    "w-4 h-4 text-purple-600 bg-gray-100 border-gray-300 rounded focus:ring-purple-500 dark:focus:ring-purple-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600 cursor-pointer"
  end
end
