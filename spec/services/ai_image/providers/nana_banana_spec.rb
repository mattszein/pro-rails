require "rails_helper"
require "base64"

# Runs the real RubyLLM chat/protocol code and only replaces the HTTP layer, so a change in
# RubyLLM's request/response shape (e.g. attachments, provider options) fails here.
RSpec.describe AiImage::Providers::NanaBanana do
  let(:png) { Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==") }
  let(:requests) { [] }

  around do |example|
    original_key = RubyLLM.config.gemini_api_key
    example.run
  ensure
    RubyLLM.configure { |config| config.gemini_api_key = original_key }
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("GOOGLE_API_KEY", nil).and_return("test-key")
  end

  def stub_gemini_reply(parts)
    body = {
      "candidates" => [{"content" => {"role" => "model", "parts" => parts}, "finishReason" => "STOP"}],
      "usageMetadata" => {}
    }
    allow_any_instance_of(RubyLLM::Transport::Connection).to receive(:post) do |_connection, url, payload, **|
      requests << {url: url, payload: payload.deep_stringify_keys}
      double("response", body: body, status: 200, headers: {}, env: nil)
    end
  end

  describe "#generate" do
    context "when Gemini returns an inline image" do
      before do
        stub_gemini_reply([{"inlineData" => {"mimeType" => "image/png", "data" => Base64.strict_encode64(png)}}])
      end

      it "returns the image bytes and content type" do
        result = described_class.new.generate("a pixel art cat")

        expect(result[:content_type]).to eq("image/png")
        expect(result[:io].read).to eq(png)
      end

      it "asks the image model for an image-only response" do
        described_class.new.generate("a pixel art cat")

        expect(requests.last[:url]).to eq("models/gemini-2.5-flash-image:generateContent")
        expect(requests.last[:payload].dig("generationConfig", "responseModalities")).to eq(["image"])
      end
    end

    context "when Gemini replies with text only" do
      before { stub_gemini_reply([{"text" => "I cannot draw that"}]) }

      it "raises a GenerationError" do
        expect { described_class.new.generate("a pixel art cat") }
          .to raise_error(AiImage::Generator::GenerationError, "Nano Banana returned no image")
      end
    end

    context "when the provider call fails" do
      before do
        allow_any_instance_of(RubyLLM::Transport::Connection)
          .to receive(:post).and_raise(RubyLLM::Error.new("boom"))
      end

      it "wraps the error in a GenerationError" do
        expect { described_class.new.generate("a pixel art cat") }
          .to raise_error(AiImage::Generator::GenerationError, "Nano Banana generation failed: boom")
      end
    end
  end
end
