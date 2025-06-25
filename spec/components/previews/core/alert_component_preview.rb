class Core::AlertComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param title
  # @param message
  # @param type select [notice alert]
  def playground(title: "Alert", message: "This is an alert", type: :notice)
    render Core::AlertComponent.new(title: title, message: message, type: type)
  end

  # @label Notice (default)
  def info
    render(Core::AlertComponent.new(title: "Info", message: "This is a Notice", type: :notice))
  end

  # @label Alert
  def alert
    render(Core::AlertComponent.new(title: "Alert", message: "This is an Alert", type: :alert))
  end
end
