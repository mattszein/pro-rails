class Core::Form::ToggleComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param object_name
  # @param method_name
  # @param checked_value
  # @param unchecked_value
  # @param theme select [primary, secondary]
  # @param size select [sm, md, lg]
  def playground(object_name: "Input", method_name: "check", checked_value: "1", unchecked_value: "0", theme: :primary, size: :md)
    render Core::Form::ToggleComponent.new(form_builder, object_name, method_name, checked_value, unchecked_value, {custom_style: {theme: theme, size: size}})
  end

  # @!group Themes

  # @label Primary (default)
  def primary
    render Core::Form::ToggleComponent.new(form_builder, "input", "primary", "1", "0", {custom_style: {theme: :primary}})
  end

  # @label Secondary
  def secondary
    render Core::Form::ToggleComponent.new(form_builder, "input", "primary", "1", "0", {custom_style: {theme: :secondary}})
  end
  # @!endgroup

  # @!group Sizes

  # @label Small
  def small
    render Core::Form::ToggleComponent.new(form_builder, "input", "primary", "1", "0", {custom_style: {size: :sm}})
  end

  # @label Medium (default)
  def medium
    render Core::Form::ToggleComponent.new(form_builder, "input", "primary", "1", "0", {custom_style: {size: :md}})
  end

  # @label Large
  def large
    render Core::Form::ToggleComponent.new(form_builder, "input", "primary", "1", "0", {custom_style: {size: :lg}})
  end
  # @!endgroup
  #

  protected

  include Core::Form::LookbookFormHelper
end
