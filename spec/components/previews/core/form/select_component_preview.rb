class Core::Form::SelectComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    form = form_builder("input")
    html = form.select("name", options)
    html.html_safe
  end

  # @!group Multiselect

  # @label Default
  def multiselect
    form = form_builder("input")
    html = form.multi_select("name", options, {}, {class: "h-10", "data-controller": "core--form--select-component"})
    html.html_safe
  end

  # @label No Empty
  def noempty
    form = form_builder("input")
    html = form.multi_select("name", options, {selected: [options[0][1]]}, {class: "h-10", "data-controller": "core--form--select-component", "data-core--form--select-component-submit-value": "true", "data-core--form--select-component-allow-empty-value": "false"})
    html.html_safe
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
