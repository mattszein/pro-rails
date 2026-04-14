# frozen_string_literal: true

module AvatarAi
  class ConceptGenerator
    class GenerationError < StandardError; end

    def initialize(model: nil)
      @model = model || AvatarAiConfig.text_model || "gpt-4o-mini"
    end

    # Returns an array of 3 concept descriptions (1-2 sentences each)
    def generate(spark_text:, style:, color_preference: nil)
      response = RubyLLM.chat(model: @model).ask(build_prompt(spark_text, style, color_preference))
      parse_concepts(response.content)
    rescue RubyLLM::Error => e
      raise GenerationError, "Concept generation failed: #{e.message}"
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

    def parse_concepts(content)
      concepts = JSON.parse(content.strip)
      raise GenerationError, "Expected array" unless concepts.is_a?(Array)
      concepts.first(3)
    rescue JSON::ParserError
      content.scan(/"([^"]+)"/).flatten.first(3)
    end
  end
end
