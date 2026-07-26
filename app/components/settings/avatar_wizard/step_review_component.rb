class Settings::AvatarWizard::StepReviewComponent < ApplicationViewComponent
  option :avatar

  def review_back_step
    avatar.max_wizard_step.to_s
  end

  def guided?
    avatar.generation_method == "guided"
  end

  def dna_summary_rows
    if guided?
      guided_dna_rows
    else
      freeform_dna_rows
    end
  end

  private

  def guided_dna_rows
    fields = %w[style archetype color_mood mood background]
    rows = fields.filter_map do |key|
      value = avatar.dna[key]
      next if value.blank?
      {label: t("avatars.dna.#{key}"), value: value.humanize}
    end

    if avatar.dna["elements"]&.any?
      rows << {label: t("avatars.dna.elements"), value: avatar.dna["elements"].join(", ")}
    end

    rows
  end

  def freeform_dna_rows
    rows = []

    if (spark = avatar.dna["spark_text"]).present?
      rows << {label: t("avatars.dna.spark_text"), value: spark}
    end

    selected_indices = Array(avatar.dna["mood_board_selected"]).map(&:to_i)
    prompts = avatar.dna["mood_board_prompts"] || []
    selected_prompts = selected_indices.filter_map { |i| prompts[i] }
    if selected_prompts.any?
      rows << {label: t("avatars.dna.mood_board_selected"), value: selected_prompts.join(" · ")}
    end

    if (style = avatar.dna["style_choice"]).present?
      rows << {label: t("avatars.dna.style_choice"),
               value: t("avatars.styles.#{style}", default: style.humanize)}
    end

    if (idx = avatar.dna["concept_choice"]).present?
      text = Array(avatar.dna["concepts"])[idx.to_i].presence || idx
      rows << {label: t("avatars.dna.concept_choice"), value: text}
    end

    %w[color_preference background].each do |key|
      if (val = avatar.dna[key]).present?
        rows << {label: t("avatars.dna.#{key}"), value: val.humanize}
      end
    end

    rows
  end
end
