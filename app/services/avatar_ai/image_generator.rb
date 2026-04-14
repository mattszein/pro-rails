# frozen_string_literal: true

module AvatarAi
  class ImageGenerator
    class GenerationError < StandardError; end

    MODELS = [
      {id: "nano_banana", label: "Nano Banana (Gemini 2.5 Flash)"},
      {id: "qwen", label: "Qwen Image 2.0 Pro"}
    ].freeze

    DEFAULT_MODEL = "nano_banana"

    def initialize(model: nil)
      @model = model.presence || DEFAULT_MODEL
    end

    # Returns {io: <StringIO or IO>, content_type: String}
    def generate(prompt)
      case @model
      when "nano_banana"
        AvatarAi::NanaBananaService.new.generate(prompt)
      when "qwen"
        AvatarAi::QwenService.new.generate(prompt)
      else
        url_based_generate(prompt)
      end
    rescue GenerationError
      raise
    rescue => e
      raise GenerationError, "Image generation failed: #{e.message}"
    end

    private

    def url_based_generate(prompt)
      result = RubyLLM.paint(prompt, model: @model)
      url = extract_url(result)
      raise GenerationError, "No image URL returned from provider" unless url

      require "open-uri"
      io = URI.parse(url).open
      content_type = io.content_type.presence || "image/png"
      {io: StringIO.new(io.read), content_type: content_type}
    rescue RubyLLM::Error => e
      raise GenerationError, "Image generation failed: #{e.message}"
    end

    def extract_url(result)
      return result.url if result.respond_to?(:url)
      return result["url"] if result.respond_to?(:[])
      nil
    end
  end
end
