class Core::Form::NumberFieldComponentPreview < ViewComponent::Preview
  # Form components are used the same way than basic rails forms.
  #
  # ```erb
  # <%= form_with model: @user do |f| %>
  #   <%= f.text_area :name %>
  # <% end %>
  # ```
  #
  # See [https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-text_area](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-text_area).

  # @label Playground
  # @param method_name
  # @param object_name
  # @param theme select [primary, secondary]
  # @param size select [sm, md]
  def playground(method_name: "name", object_name: "input", theme: :primary, size: :md)
    render Core::Form::NumberFieldComponent.new(form_builder, object_name, method_name, {custom_style: {theme: theme, size: size}})
  end

  # @!group Themes
  def primary
    render Core::Form::NumberFieldComponent.new(form_builder, "input", "name", {custom_style: {theme: :primary}})
  end

  def secondary
    render Core::Form::NumberFieldComponent.new(form_builder, "input", "name", {custom_style: {theme: :secondary}})
  end

  # @!endgroup

  # @!group Sizes

  def small
    render Core::Form::NumberFieldComponent.new(form_builder, "input", "name", {custom_style: {size: :sm}})
  end

  def medium
    render Core::Form::NumberFieldComponent.new(form_builder, "input", "name", {custom_style: {size: :md}})
  end
  # @!endgroup

  def with_floating_label
    render(Core::Form::LabeledComponent.new(form_builder, "input", "name", nil, nil)) do |component|
      component.render(Core::Form::NumberFieldComponent.new(form_builder, "input", "name", {placeholder: ""}))
    end
  end

  protected

  include Core::Form::LookbookFormHelper
end
