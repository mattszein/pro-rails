# Stubs only the HTTP layer (like spec/services/avatar_ai/base_generator_spec.rb) so the real
# RubyLLM chat, tool loop and request building run. Each call to the stubbed `post` returns the
# next queued OpenRouter body.
module SupportAiLlmHelpers
  def with_openrouter_key
    original = RubyLLM.config.openrouter_api_key
    RubyLLM.configure { |config| config.openrouter_api_key = "test-key" }
    yield
  ensure
    RubyLLM.configure { |config| config.openrouter_api_key = original }
  end

  def text_body(content, prompt_tokens: 10, completion_tokens: 5)
    {
      "id" => "gen-1", "model" => "stub",
      "choices" => [{"index" => 0, "message" => {"role" => "assistant", "content" => content}, "finish_reason" => "stop"}],
      "usage" => {"prompt_tokens" => prompt_tokens, "completion_tokens" => completion_tokens, "total_tokens" => prompt_tokens + completion_tokens}
    }
  end

  # calls: [[name, {args}], ...]
  def tool_call_body(calls, content: nil)
    tool_calls = calls.each_with_index.map do |(name, args), i|
      {"id" => "call_#{SecureRandom.hex(4)}_#{i}", "type" => "function", "function" => {"name" => name, "arguments" => args.to_json}}
    end
    {
      "id" => "gen-tc", "model" => "stub",
      "choices" => [{"index" => 0, "message" => {"role" => "assistant", "content" => content, "tool_calls" => tool_calls}, "finish_reason" => "tool_calls"}],
      "usage" => {"prompt_tokens" => 10, "completion_tokens" => 5, "total_tokens" => 15}
    }
  end

  # Queues bodies; returns the array that collects each request payload (string keys).
  def stub_llm(*bodies)
    requests = []
    queue = bodies.dup
    allow_any_instance_of(RubyLLM::Transport::Connection).to receive(:post) do |_connection, _url, payload, **|
      requests << payload.deep_stringify_keys
      double("response", body: (queue.size > 1) ? queue.shift : queue.first, status: 200, headers: {}, env: nil)
    end
    requests
  end
end

RSpec.configure do |config|
  config.include SupportAiLlmHelpers, type: :service
  config.include SupportAiLlmHelpers, :llm
end
