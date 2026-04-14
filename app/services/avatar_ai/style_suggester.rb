# frozen_string_literal: true

module AvatarAi
  class StyleSuggester
    class SuggestionError < StandardError; end

    STYLES = %w[
      pixel_art watercolor geometric anime 3d_clay
      line_art collage surrealist retro_sci_fi vaporwave
      impressionist gothic cyberpunk fantasy
    ].freeze

    def initialize(model: nil)
      @model = model || AvatarAiConfig.text_model || "gpt-4o-mini"
    end

    # Returns array of style suggestions (up to 4) with labels
    def suggest(spark_text:, mood_board_selected:)
      response = RubyLLM.chat(model: @model).ask(build_prompt(spark_text, mood_board_selected))
      parse_suggestions(response.content)
    rescue RubyLLM::Error => e
      raise SuggestionError, "Style suggestion failed: #{e.message}"
    end

    private

    def build_prompt(spark_text, selected_indices)
      <<~PROMPT
        Based on this avatar concept: "#{spark_text}"
        And selected mood board thumbnails at indices: #{selected_indices.inspect}

        Suggest 4 art styles from this list that best match the concept:
        #{STYLES.join(", ")}

        Return ONLY a JSON array of style keys (max 4):
        Example: ["pixel_art", "anime", "geometric", "watercolor"]
      PROMPT
    end

    def parse_suggestions(content)
      styles = JSON.parse(content.strip)
      styles.select { |s| STYLES.include?(s) }.first(4)
    rescue JSON::ParserError
      STYLES.first(4)
    end
  end
end
