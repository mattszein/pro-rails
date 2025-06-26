class Core::AlertComponent < ViewComponent::Base
  attr_reader :type, :title, :message

  TYPES = {notice: "text-green-800 bg-green-50 dark:text-green-400", alert: "text-red-800 bg-red-50 dark:text-red-400"}.freeze

  CLOSE_BUTTONS = {notice: "text-green-500 hover:text-green-800 focus:ring-green-100", alert: "text-red-500 hover:text-red-800 focus:ring-red-100"}.freeze

  def initialize(type: :notice, title: nil, message: nil)
    @type = type
    @title = title
    @message = message
  end
end
