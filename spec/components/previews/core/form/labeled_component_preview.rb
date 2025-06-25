class Core::Form::LabeledComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param object_name
  # @param method_name
  # @param theme select [primary, secondary]
  # @param style select [default, filled]
  def playground(object_name: "input", method_name: "name", theme: :primary, style: :default)
    render(Core::Form::LabeledComponent.new(form_builder, object_name, method_name, nil, {custom_style: {theme: theme, style: style}})) do |component|
      component.render(Core::Form::TextFieldComponent.new(form_builder, "input", "name", {placeholder: "", custom_style: {theme: theme}}))
    end
  end

  # @!group Styles

  def default
    render(Core::Form::LabeledComponent.new(form_builder, "default", "name", nil, {custom_style: {style: :default}})) do |component|
      component.render(Core::Form::TextFieldComponent.new(form_builder, "default", "name", {placeholder: ""}))
    end
  end

  def filled
    render(Core::Form::LabeledComponent.new(form_builder, "filled", "name", nil, {custom_style: {style: :filled}})) do |component|
      component.render(Core::Form::TextFieldComponent.new(form_builder, "filled", "name", {placeholder: ""}))
    end
  end

  # @!endgroup

  # @!group Themes

  def primary
    render(Core::Form::LabeledComponent.new(form_builder, "primary", "name", nil, {custom_style: {theme: :primary}})) do |component|
      component.render(Core::Form::TextFieldComponent.new(form_builder, "primary", "name", {placeholder: "", custom_style: {theme: :primary}}))
    end
  end

  def secondary
    render(Core::Form::LabeledComponent.new(form_builder, "secondary", "name", nil, {custom_style: {theme: :secondary}})) do |component|
      component.render(Core::Form::TextFieldComponent.new(form_builder, "secondary", "name", {placeholder: "", custom_style: {theme: :secondary}}))
    end
  end

  # @!endgroup

  protected

  include Core::Form::LookbookFormHelper
end
