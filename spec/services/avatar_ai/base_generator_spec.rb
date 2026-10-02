require "rails_helper"

# Runs the real RubyLLM chat code and only replaces the HTTP layer, so a change in how RubyLLM
# resolves models or builds the request fails here.
RSpec.describe AvatarAi::BaseGenerator do
  let(:requests) { [] }
  let(:reply) { "[\"pixel\", \"neon\"]" }

  around do |example|
    original_key = RubyLLM.config.openrouter_api_key
    RubyLLM.configure { |config| config.openrouter_api_key = "test-key" }
    example.run
  ensure
    RubyLLM.configure { |config| config.openrouter_api_key = original_key }
  end

  def stub_openrouter_reply
    body = {
      "id" => "gen-1",
      "model" => "stub",
      "choices" => [{"index" => 0, "message" => {"role" => "assistant", "content" => reply}, "finish_reason" => "stop"}],
      "usage" => {"prompt_tokens" => 1, "completion_tokens" => 1, "total_tokens" => 2}
    }
    allow_any_instance_of(RubyLLM::Transport::Connection).to receive(:post) do |_connection, url, payload, **|
      requests << {url: url, payload: payload.deep_stringify_keys}
      double("response", body: body, status: 200, headers: {}, env: nil)
    end
  end

  describe "#ask" do
    it "sends the configured OpenRouter model id even when ruby_llm's bundled registry does not list it" do
      stub_openrouter_reply

      message = described_class.new(model: "openai/gpt-oss-120b:free").send(:ask, "two words")

      expect(message.content).to eq(reply)
      expect(requests.last[:url]).to eq("chat/completions")
      expect(requests.last[:payload]["model"]).to eq("openai/gpt-oss-120b:free")
    end

    it "uses the configured default text model when none is given" do
      stub_openrouter_reply

      described_class.new.send(:ask, "two words")

      expect(requests.last[:payload]["model"]).to eq(AvatarAiConfig.text_model)
    end

    it "wraps provider errors in a GenerationError" do
      allow_any_instance_of(RubyLLM::Transport::Connection)
        .to receive(:post).and_raise(RubyLLM::Error.new("boom"))

      expect { described_class.new.send(:ask, "two words") }
        .to raise_error(described_class::GenerationError, "AvatarAi::BaseGenerator failed: boom")
    end
  end
end
