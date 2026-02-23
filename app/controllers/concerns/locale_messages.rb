module LocaleMessages
  def resource_message(key, resource)
    model = resource.is_a?(Class) ? resource : resource.class
    I18n.t("messages.#{key}", model: model.model_name.human)
  end
end
