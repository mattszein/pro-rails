class Core::Form::PasswordFieldComponent < Core::Form::FieldComponent
  include Core::Form::InputClasses

  def call
    ActionView::Helpers::Tags::PasswordField.new(object_name, method_name, @view_context, options).render
  end
end
