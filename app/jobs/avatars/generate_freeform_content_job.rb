# frozen_string_literal: true

module Avatars
  class GenerateFreeformContentJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(avatar_id, step)
      avatar = Avatar.find_by(id: avatar_id)
      return unless avatar
      return unless avatar.draft? && avatar.generated?

      text_model = avatar.dna["text_model"].presence || AvatarAiConfig.text_model

      case step
      when "2"
        return if avatar.dna["mood_board_prompts"].present?
        spark = avatar.dna["spark_text"].presence
        return unless spark
        prompts = AvatarAi::MoodBoardGenerator.new(model: text_model).generate_thumbnail_prompts(spark)
        avatar.update!(dna: avatar.dna.merge("mood_board_prompts" => prompts))
      when "3"
        return if avatar.dna["style_suggestions"].present?
        spark = avatar.dna["spark_text"].presence
        return unless spark
        suggestions = AvatarAi::StyleSuggester.new(model: text_model).suggest(
          spark_text: spark,
          mood_board_selected: avatar.dna["mood_board_selected"] || []
        )
        avatar.update!(dna: avatar.dna.merge("style_suggestions" => suggestions))
      when "4"
        return if avatar.dna["concepts"].present?
        style = avatar.dna["style_choice"].presence
        return unless style
        concepts = AvatarAi::ConceptGenerator.new(model: text_model).generate(
          spark_text: avatar.dna["spark_text"] || "",
          style: style,
          color_preference: avatar.dna["color_preference"]
        )
        avatar.update!(dna: avatar.dna.merge("concepts" => concepts))
      end

      avatar.reload
      broadcast_step(avatar, step)
    end

    private

    def broadcast_step(avatar, step)
      Turbo::StreamsChannel.broadcast_update_to(
        "avatar_#{avatar.id}_wizard",
        target: "avatar_wizard_step",
        partial: "settings/avatars/wizard_freeform_step_#{step}",
        locals: {avatar: avatar}
      )
    end
  end
end
