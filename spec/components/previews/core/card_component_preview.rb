class Core::CardComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param padding select [sm, md, lg, xl]
  def playground(padding: :lg)
    render(Core::CardComponent.new({padding: padding})) do |component|
      "<p>This is the card body</p>".html_safe
    end
  end
end
