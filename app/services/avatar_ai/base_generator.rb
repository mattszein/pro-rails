module AvatarAi
  class BaseGenerator
    class GenerationError < StandardError; end

    def initialize(model: nil)
      @model = model.presence || AvatarAiConfig.text_model
    end

    private

    TIMEOUT = 120

    # Returns the reply text. Goes through Llm::Runner (OpenRouter model ids, ":free" variants
    # included, registry lookup skipped); provider failures surface as GenerationError.
    def ask(prompt)
      runner.call(model: @model) { |chat| chat.ask(prompt).content.to_s }.output
    rescue Llm::Error => e
      raise GenerationError, "#{self.class.name} failed: #{e.cause&.message || e.message}"
    end

    def runner
      @runner ||= Llm::Runner.new(timeout: TIMEOUT)
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
