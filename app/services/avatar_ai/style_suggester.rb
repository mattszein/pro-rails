# frozen_string_literal: true

module AvatarAi
  class StyleSuggester < BaseGenerator
    STYLES = %w[
      pixel_art watercolor geometric anime 3d_clay
      line_art collage surrealist retro_sci_fi vaporwave
      impressionist gothic cyberpunk fantasy
    ].freeze

    def suggest(spark_text:, mood_board_selected:)
      response = ask(build_prompt(spark_text, mood_board_selected))
      parse_suggestions(response.content)
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
      parse_json_array(content).select { |s| STYLES.include?(s) }.first(4)
    end
  end
end
