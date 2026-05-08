class Settings::AvatarWizard::MultiSelectStepComponent < ApplicationViewComponent
  option :avatar
  option :config  # NavigableStep

  def mood_board?
    config.component == :mood_board
  end

  def loading?
    config.loading_field && avatar.dna[config.loading_field].blank?
  end

  def options
    t("#{config.i18n_key}.options")
  end

  def selected_values
    Array(avatar.dna[config.dna_field])
  end

  def mood_board_prompts
    avatar.dna["mood_board_prompts"] || []
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

  def cancel_url
    edit_settings_profile_path
  end
end
