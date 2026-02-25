class Core::LinkComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param name
  # @param style select [default, as_button, no_style]
  # @param theme select [primary, secondary, create]
  # @param size select [sm, md, lg, xlg, giant]
  def playground(name: "Link", style: :default, theme: :primary, size: :md)
    render(Core::LinkComponent.new(name: name, url: "#", style: style, theme: theme, size: size))
  end

  # @!group Styles
  # @label Default (default)
  def default
    render(Core::LinkComponent.new(name: "Link", url: "#", style: :default))
  end

  # @label As button
  def as_button
    render(Core::LinkComponent.new(name: "Link", url: "#", style: :as_button))
  end

  # @label No style
  def no_style
    render(Core::LinkComponent.new(name: "Link", url: "#", style: :no_style))
  end
end
