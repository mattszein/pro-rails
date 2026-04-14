# frozen_string_literal: true

module AvatarAi
  class MoodBoardGenerator
    class GenerationError < StandardError; end

    def initialize(model: nil)
      @text_model = model || AvatarAiConfig.text_model || "gpt-4o-mini"
      @image_model = AvatarAiConfig.default_image_model || "dall-e-3"
      @thumbnail_count = AvatarAiConfig.mood_board_thumbnail_count || 9
    end

    # Returns an array of prompt strings (one per thumbnail)
    # The actual images are generated as separate jobs
    def generate_thumbnail_prompts(spark_text)
      response = RubyLLM.chat(model: @text_model).ask(build_prompt(spark_text))
      parse_prompts(response.content)
    rescue RubyLLM::Error => e
      raise GenerationError, "Mood board prompt generation failed: #{e.message}"
    end

    private

    def build_prompt(spark_text)
      <<~PROMPT
        Generate #{@thumbnail_count} distinct visual avatar concept prompts based on this description: "#{spark_text}"

        Each prompt should:
        - Be 1-2 sentences describing a unique visual interpretation
        - Be suitable for AI image generation (dall-e style)
        - Vary in style, mood, and aesthetic approach
        - Focus on avatar/portrait compositions

        Return ONLY a JSON array of strings, nothing else.
        Example: ["prompt 1", "prompt 2", ...]
      PROMPT
    end

    def parse_prompts(content)
      prompts = JSON.parse(content.strip)
      raise GenerationError, "Expected array of prompts" unless prompts.is_a?(Array)
      prompts.first(@thumbnail_count)
    rescue JSON::ParserError
      # Fallback: extract quoted strings
      content.scan(/"([^"]+)"/).flatten.first(@thumbnail_count)
    end
  end
end
