# frozen_string_literal: true

class Settings::AvatarWizard::MultiSelectStepComponent < ApplicationViewComponent
  option :avatar
  option :config

  def mood_board?
    config[:component] == :mood_board
  end

  def loading?
    config[:loading_field] && avatar.dna[config[:loading_field]].blank?
  end

  def options
    t("#{config[:i18n_key]}.options")
  end

  def selected_values
    Array(avatar.dna[config[:dna_field]])
  end

  def back_url
    if config[:back_step]
      settings_avatar_path(avatar, step: config[:back_step])
    else
      edit_settings_profile_path
    end
  end

  def back_label
    config[:back_step] ? t("shared.common.back") : t("shared.common.cancel")
  end

  def back_turbo_frame
    config[:back_step] ? "avatar_wizard_step" : "_top"
  end

  def submit_label
    config[:final_step] ? t("avatars.wizard.review") : t("shared.common.next")
  end

  def grid_class
    cols = config[:columns] || 3
    "grid grid-cols-2 sm:grid-cols-#{cols} gap-3"
  end
end
