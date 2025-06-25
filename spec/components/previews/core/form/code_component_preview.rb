class Core::Form::CodeComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param length number
  # @param input_name
  def playground(length: 5, input_name: "token")
    render(Core::Form::CodeComponent.new(form_builder, nil, input_name, length))
  end

  protected

  include Core::Form::LookbookFormHelper
end
