# frozen_string_literal: true

class Core::AiModelSelectorComponent < ApplicationViewComponent
  option :kind           # :text | :image
  option :current_model  # String — currently selected model id
  option :field_name     # String — HTML input name attribute

  def models
    case kind
    when :text then AvatarAiConfig::TEXT_MODELS
    when :image then AvatarAiConfig::IMAGE_MODELS
    end
  end

  def label
    case kind
    when :text then t("avatars.freeform.text_model_label")
    when :image then t("avatars.wizard.model_label")
    end
  end
end
