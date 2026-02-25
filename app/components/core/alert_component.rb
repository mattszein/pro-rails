class Core::AlertComponent < ApplicationViewComponent
  option :type, default: -> { :notice }
  option :title, default: -> {}
  option :message, default: -> {}

  STYLES = {
    notice: "text-green-800 bg-green-50 dark:text-green-400",
    alert: "text-red-800 bg-red-50 dark:text-red-400"
  }.freeze

  CLOSE_BUTTON_STYLES = {
    notice: "text-green-500 hover:text-green-800 focus:ring-green-100",
    alert: "text-red-500 hover:text-red-800 focus:ring-red-100"
  }.freeze

  def html_class
    STYLES[type]
  end

  def close_button_class
    CLOSE_BUTTON_STYLES[type]
  end
end
