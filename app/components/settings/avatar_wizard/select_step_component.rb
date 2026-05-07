# frozen_string_literal: true

class Settings::AvatarWizard::SelectStepComponent < ApplicationViewComponent
  option :avatar
  option :config  # NavigableStep

  def options
    config.dynamic_options ? build_dynamic_options : t("#{config.i18n_key}.options")
  end

  def selected?(key)
    avatar.dna[config.dna_field] == key.to_s
  end

  def loading?
    config.loading_field && avatar.dna[config.loading_field].blank?
  end

  def stacked_variant?
    config.variant == :stacked
  end

  def back_url
    config.back_step ? settings_avatar_path(avatar, step: config.back_step) : edit_settings_profile_path
  end

  def back_label
    config.back_step ? t("shared.common.back") : t("shared.common.cancel")
  end

  def back_turbo_frame
    config.back_step ? "avatar_wizard_step" : "_top"
  end

  def submit_label
    config.final? ? t("avatars.wizard.review") : t("shared.common.next")
  end

  private

  def build_dynamic_options
    field = config.dynamic_options
    raw = avatar.dna[field]

    if field == "concepts"
      Array(raw).each_with_index.to_h do |concept, index|
        [index.to_s, {label: concept}]
      end
    else
      styles = Array(raw).presence || AvatarAi::StyleSuggester::STYLES.first(4)
      styles.index_with { |style| {label: t("avatars.styles.#{style}", default: style.humanize)} }
    end
  end
end
