module AvatarAi
  class BaseGenerator
    class GenerationError < StandardError; end

    def initialize(model: nil)
      @model = model.presence || AvatarAiConfig.text_model
    end

    private

    # Model ids are OpenRouter ids (see AvatarAiConfig::TEXT_MODELS), including ":free" variants that
    # rotate faster than ruby_llm's bundled registry, so skip the registry lookup.
    def ask(prompt)
      RubyLLM.chat(model: @model, provider: :openrouter, assume_model_exists: true).ask(prompt)
    rescue RubyLLM::Error => e
      raise GenerationError, "#{self.class.name} failed: #{e.message}"
    end

    def parse_json_array(content, limit: nil)
      arr = JSON.parse(content.strip)
      raise GenerationError, "Expected array" unless arr.is_a?(Array)
      limit ? arr.first(limit) : arr
    rescue JSON::ParserError
      matches = content.scan(/"([^"]+)"/).flatten
      limit ? matches.first(limit) : matches
    end
  end
end
