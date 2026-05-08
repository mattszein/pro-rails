
require "net/http"
require "uri"
require "json"

module AiImage
  module Providers
    # Uses Alibaba DashScope Qwen image generation API directly.
    # The DashScope multimodal API uses a chat-style payload, not the standard
    # image generation format, so ruby_llm cannot wrap it.
    class Qwen
      ENDPOINT = "https://dashscope-intl.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
      MODEL = "qwen-image-2.0-pro"
      NEGATIVE_PROMPT = "Low resolution, low quality, distorted limbs, malformed fingers, oversaturated colors, wax-figure appearance, lack of facial detail, excessive smoothness, AI-looking artifacts, chaotic composition, blurry or warped text."

      def generate(prompt, size: "512*512")
        url = request_image_url(prompt, size:)
        download_image(url)
      end

      private

      def request_image_url(prompt, size:)
        uri = URI(ENDPOINT)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{api_key}"
        request.body = JSON.dump(
          model: MODEL,
          input: {
            messages: [{role: "user", content: [{text: prompt}]}]
          },
          parameters: {
            size: size,
            prompt_extend: true,
            watermark: false,
            negative_prompt: NEGATIVE_PROMPT
          }
        )

        response = http.request(request)
        parsed = JSON.parse(response.body)

        unless response.is_a?(Net::HTTPSuccess) && parsed.dig("output", "choices")
          raise AiImage::Generator::GenerationError,
            "Qwen API error: #{parsed["message"] || parsed.inspect}"
        end

        image_url = parsed.dig("output", "choices", 0, "message", "content", 0, "image")
        raise AiImage::Generator::GenerationError, "Qwen returned no image URL" unless image_url

        image_url
      end

      def download_image(url)
        require "open-uri"
        uri = URI.parse(url)
        unless %w[http https].include?(uri.scheme)
          raise AiImage::Generator::GenerationError, "Only HTTP(S) URLs are allowed"
        end
        io = uri.open
        content_type = io.content_type.presence || "image/jpeg"
        {io: StringIO.new(io.read), content_type: content_type}
      rescue URI::InvalidURIError
        raise AiImage::Generator::GenerationError, "Invalid URL returned from Qwen provider"
      rescue AiImage::Generator::GenerationError
        raise
      rescue => e
        raise AiImage::Generator::GenerationError, "Failed to download Qwen image: #{e.message}"
      end

      def api_key
        ENV.fetch("DASHSCOPE_API_KEY", nil)
      end
    end
  end
end
