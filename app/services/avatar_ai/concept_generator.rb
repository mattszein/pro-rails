# frozen_string_literal: true

module AvatarAi
  class ConceptGenerator < BaseGenerator
    def generate(spark_text:, style:, color_preference: nil)
      response = ask(build_prompt(spark_text, style, color_preference))
      parse_json_array(response.content, limit: 3)
    end

    private

    def build_prompt(spark_text, style, color_preference)
      color_hint = color_preference ? " with #{color_preference} colors" : ""

      <<~PROMPT
        Create 3 distinct avatar concept descriptions for: "#{spark_text}"
        Art style: #{style.humanize}#{color_hint}

        Each concept should be 1-2 sentences, vivid and specific, describing how the avatar would look.
        Make each interpretation meaningfully different.

        Return ONLY a JSON array of 3 strings:
        ["concept 1", "concept 2", "concept 3"]
      PROMPT
    end
  end
end
