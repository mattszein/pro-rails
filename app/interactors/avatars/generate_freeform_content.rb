module Avatars
  class GenerateFreeformContent
    include Interactor

    delegate :avatar, :step, to: :context

    def call
      return unless avatar.draft? && avatar.generated?

      case step
      when "2" then generate_mood_board_prompts
      when "3" then generate_style_suggestions
      when "4" then generate_concepts
      end

      avatar.reload
      broadcast_step
    rescue => e
      context.fail!(error: e.message)
    end

    private

    def text_model
      avatar.dna["text_model"].presence || AvatarAiConfig.text_model
    end

    def generate_mood_board_prompts
      return if avatar.dna["mood_board_prompts"].present?
      spark = avatar.dna["spark_text"].presence
      return unless spark

      prompts = AvatarAi::MoodBoardGenerator.new(model: text_model).generate_thumbnail_prompts(spark)
      avatar.update!(dna: avatar.dna.merge("mood_board_prompts" => prompts))
    end

    def generate_style_suggestions
      return if avatar.dna["style_suggestions"].present?
      spark = avatar.dna["spark_text"].presence
      return unless spark

      suggestions = AvatarAi::StyleSuggester.new(model: text_model).suggest(
        spark_text: spark,
        mood_board_selected: avatar.dna["mood_board_selected"] || []
      )
      avatar.update!(dna: avatar.dna.merge("style_suggestions" => suggestions))
    end

    def generate_concepts
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

    def broadcast_step
      Turbo::StreamsChannel.broadcast_update_to(
        "avatar_#{avatar.id}_wizard",
        target: "avatar_wizard_step",
        partial: "settings/avatars/wizard_freeform_step",
        locals: {avatar: avatar, step: step}
      )
    end
  end
end
