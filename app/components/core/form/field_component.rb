class Core::Form::FieldComponent < ApplicationViewComponent
  attr_reader :form, :object_name, :method_name, :options

  delegate :object, to: :form, allow_nil: true

  def initialize(form, object_name, method_name, options = {})
    @form = form
    @object_name = object_name
    @method_name = method_name
    @options = options || {}
    super()
  end

  def html_class
    nil
  end

  def before_render
    combine_options!
  end

  def has_errors? # rubocop:disable Naming/PredicateName
    object&.respond_to?(:errors) && object.errors[method_name].present?
  end

  def errors
    object&.errors&.[](method_name) || []
  end

  def value
    object&.public_send(method_name) if object&.respond_to?(method_name)
  end

  private

  def combine_options!
    return unless html_class

    @options[:class] = [html_class, @options[:class]].compact.join(" ")
  end
end
