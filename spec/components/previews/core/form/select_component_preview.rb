class Core::Form::SelectComponentPreview < ViewComponent::Preview
  CHOICES = [
    ["Option 1", "option_1"],
    ["Option 2", "option_2"],
    ["Option 3", "option_3"]
  ].freeze

  # @label Default
  def default
    render(Core::Form::SelectComponent.new(form_builder, "input", "name", CHOICES, {}, {}))
  end

  # @!group Multiselect

  # @label Default
  def multiselect
    render(Core::Form::SelectComponent.new(form_builder, "input", "name", CHOICES, {}, {multiple: true, class: "h-10"}))
  end

  # @label No Empty
  def noempty
    render(Core::Form::SelectComponent.new(
      form_builder, "input", "name", CHOICES,
      {selected: ["option_1"]},
      {multiple: true, class: "h-10", "data-controller": "core--form--select-component", "data-core--form--select-component-submit-value": "true", "data-core--form--select-component-allow-empty-value": "false"}
    ))
  end

  # @!endgroup

  protected

  include Core::Form::LookbookFormHelper
end
