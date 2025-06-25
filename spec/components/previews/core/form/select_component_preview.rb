class Core::Form::SelectComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render ViewComponent::Form::SelectComponent.new(form_builder, "input", "name", options)
  end

  # @!group Multiselect

  # @label Default
  def multiselect
    render ViewComponent::Form::SelectComponent.new(form_builder, "input", "name", options, {}, {class: "h-10", multiple: true, "data-controller": "core--form--select-component"})
  end

  # @label No Empty
  def noempty
    render ViewComponent::Form::SelectComponent.new(form_builder, "input", "name", options, {selected: [options[0][1]]}, {class: "h-10", multiple: true, "data-controller": "core--form--select-component", "data-core--form--select-component-submit-value": "true", "data-core--form--select-component-allow-empty-value": "false"})
  end

  # @!endgroup
  protected

  def options
    [
      ["Option 1", "option_1"],
      ["Option 2", "option_2"],
      ["Option 3", "option_3"]
    ]
  end

  include Core::Form::LookbookFormHelper
end
