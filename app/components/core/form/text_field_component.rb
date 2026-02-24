class Core::Form::TextFieldComponent < Core::Form::FieldComponent
  include Core::Form::InputClasses

  def call
    ActionView::Helpers::Tags::TextField.new(object_name, method_name, @view_context, options).render
  end
end
