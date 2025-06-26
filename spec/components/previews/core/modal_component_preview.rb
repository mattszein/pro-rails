class Core::ModalComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param title
  def playground(title: "Titulo")
    render Core::ModalComponent.new(title: title) do |component|
      "<p>This is the modal body</p>".html_safe
    end
  end
end
