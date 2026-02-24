class Core::Form::NumberFieldComponent < Core::Form::FieldComponent
  include Core::Form::InputClasses

  def call
    ActionView::Helpers::Tags::NumberField.new(object_name, method_name, @view_context, options).render
  end
end
