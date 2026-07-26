module AvatarAi
  class MoodBoardGenerator < BaseGenerator
    def initialize(model: nil)
      super
      @thumbnail_count = AvatarAiConfig.mood_board_thumbnail_count
    end

    def generate_thumbnail_prompts(spark_text)
      response = ask(build_prompt(spark_text))
      parse_json_array(response.content, limit: @thumbnail_count)
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
  end
end
