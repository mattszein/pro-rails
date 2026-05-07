# frozen_string_literal: true

module AiImage
  class Generator
    class GenerationError < StandardError; end

    PROVIDERS = {
      "nano_banana" => -> { AiImage::Providers::NanaBanana.new },
      "qwen" => -> { AiImage::Providers::Qwen.new }
    }.freeze

    def initialize(model: nil)
      @model = model.presence || AvatarAiConfig.default_image_model
    end

    # Returns {io: <StringIO or IO>, content_type: String}
    def generate(prompt)
      provider = PROVIDERS[@model]
      if provider
        provider.call.generate(prompt)
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
