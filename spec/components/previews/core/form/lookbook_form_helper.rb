module Core::Form::LookbookFormHelper
  def form_builder(object_name = nil, object = nil, options = {})
    CustomFormBuilder.new(object_name, object, template, options)
  end

  def template
    lookup_context = ActionView::LookupContext.new(ActionController::Base.view_paths)

    ActionView::Base.new(lookup_context, {}, ActionController::Base.new)
  end
end
