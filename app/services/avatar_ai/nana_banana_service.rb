# frozen_string_literal: true

module AvatarAi
  # Uses Gemini 2.5 Flash's image generation via RubyLLM chat endpoint.
  # Returns an IO object suitable for direct Active Storage attachment.
  class NanaBananaService
    MODEL = "gemini-2.5-flash-image"

    def generate(prompt)
      RubyLLM.configure do |config|
        config.gemini_api_key = ENV.fetch("GOOGLE_API_KEY", nil)
      end
      chat = RubyLLM.chat(model: MODEL)
                    .with_params(generationConfig: {responseModalities: ["image"]})
      response = chat.ask(prompt)
      attachment = response.content[:attachments]&.first
      raise AvatarAi::ImageGenerator::GenerationError, "Nano Banana returned no image" unless attachment

      {io: attachment.source, content_type: attachment.mime_type || "image/jpeg"}
    rescue RubyLLM::Error => e
      raise AvatarAi::ImageGenerator::GenerationError, "Nano Banana generation failed: #{e.message}"
    end
  end
end
