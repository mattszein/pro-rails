# frozen_string_literal: true

class Settings::AvatarWizard::CompoundSelectStepComponent < ApplicationViewComponent
  option :avatar
  option :config

  def back_url
    settings_avatar_path(avatar, step: config[:back_step])
  end

  def submit_label
    config[:final_step] ? t("avatars.wizard.review") : t("shared.common.next")
  end

  def section_grid_class(section)
    cols = section[:columns] || 3
    "grid grid-cols-2 sm:grid-cols-#{cols} gap-3"
  end

  def section_options(section)
    t(section[:i18n_key])
  end

  def selected_for(dna_field, key)
    avatar.dna[dna_field] == key.to_s
  end
end
