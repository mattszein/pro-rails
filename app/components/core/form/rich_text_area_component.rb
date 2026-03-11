class Core::Form::RichTextAreaComponent < Core::Form::FieldComponent
  def call
    @view_context.lexxy_rich_text_area(object_name, method_name, **options)
  end
end
