class Core::Form::DateTimeComponent < ViewComponent::Form::FieldComponent
  def initialize(form, object_name, method_name, options = {})
    super(form, object_name, method_name, options)
  end
end
