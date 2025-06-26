class Core::Form::CheckBoxComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param object_name
  # @param method_name
  # @param checked_value
  # @param unchecked_value
  def playground(object_name: "Input", method_name: "check", checked_value: "1", unchecked_value: "0", options: {})
    render Core::Form::CheckBoxComponent.new(form_builder, object_name, method_name, checked_value, unchecked_value, options)
  end

  protected

  include Core::Form::LookbookFormHelper
end
