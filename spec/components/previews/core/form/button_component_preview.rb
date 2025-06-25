# frozen_string_literal: true

class Core::Form::ButtonComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param text
  # @param theme select [primary, secondary, create]
  # @param size select [sm, md, lg, xlg, giant]
  def playground(text: "Button", theme: :primary, size: :md, options: {})
    render Core::Form::ButtonComponent.new(form_builder, text, {theme: theme, size: size}, options)
  end

  # @!group Themes

  # @label Primary (default)
  def primary
    render Core::Form::ButtonComponent.new(form_builder, "Button", {theme: :primary}, {})
  end

  # @label Secondary
  def secondary
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {theme: :secondary}, {}))
  end

  # @label Create
  def create
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {theme: :create}, {}))
  end

  # @label Edit
  def edit
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {theme: :edit}, {}))
  end

  # @label Delete
  def delete
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {theme: :delete}, {}))
  end
  # @!endgroup

  # @!group Sizes

  # @label Small
  def small
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {size: :sm}, {}))
  end

  # @label Medium (default)
  def medium
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {size: :md}, {}))
  end

  # @label Large
  def large
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {size: :lg}, {}))
  end

  # @label X-Large
  def xlarge
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {size: :xlg}, {}))
  end

  # @label Giant
  def giant
    render(Core::Form::ButtonComponent.new(form_builder, "Button", {size: :giant}, {}))
  end

  # @!endgroup

  protected

  include Core::Form::LookbookFormHelper
end
