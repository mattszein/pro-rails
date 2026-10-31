require "rails_helper"

# Runs the real RubyLLM chat code and only replaces the HTTP layer (see SupportAiLlmHelpers).
RSpec.describe Llm::Runner, :llm do
  around { |example| with_openrouter_key { example.run } }

  let(:model) { "some/model:free" }

  before do
    stub_const("EchoTool", Class.new(Llm::Tools::Base) do
      description "Echo"
      parameter :text, description: "text"

      def execute(text:) = {echo: text}
    end)
  end

  describe "#call" do
    it "returns a Result with output, usage, latency and transcript" do
      requests = stub_llm(text_body("hello", prompt_tokens: 7, completion_tokens: 3))

      result = described_class.new.call(model: model, system: "Be terse.") { |chat| chat.ask("hi").content }

      expect(result).to be_a(Llm::Result)
      expect(result.output).to eq("hello")
      expect(result.model).to eq(model)
      expect([result.input_tokens, result.output_tokens]).to eq([7, 3])
      expect(result.latency_ms).to be >= 0
      expect(result.tool_calls).to eq([])
      expect(result.transcript.pluck(:role)).to eq(%w[system user assistant])
      expect(requests.last["model"]).to eq(model)
    end

    it "sends system instructions and temperature, and skips them when nil" do
      requests = stub_llm(text_body("ok"))

      described_class.new(temperature: 0.3).call(model: model, system: "Rules") { |chat| chat.ask("hi") }
      expect(requests.last["temperature"]).to eq(0.3)
      expect(requests.last["messages"].first).to include("content" => "Rules")

      described_class.new.call(model: model) { |chat| chat.ask("hi") }
      expect(requests.last).not_to have_key("temperature")
      expect(requests.last["messages"].pluck("role")).to eq(%w[user])
    end

    it "wires the schema" do
      requests = stub_llm(text_body("{}"))
      schema = {name: "thing", strict: true, schema: {type: "object", additionalProperties: false, properties: {a: {type: "string"}}, required: ["a"]}}

      described_class.new.call(model: model, schema: schema) { |chat| chat.ask("hi") }

      expect(requests.last["response_format"]).to be_present
    end

    it "runs tools through the budget and reports the recorded calls" do
      requests = stub_llm(tool_call_body([["echo_tool", {text: "x"}]]), text_body("done"))
      budget = Llm::ToolBudget.new

      result = described_class.new.call(model: model, tools: [EchoTool.new(budget: budget)], budget: budget) { |chat| chat.ask("go").content }

      expect(result.output).to eq("done")
      expect(result.tool_calls).to eq([{name: "echo_tool", arguments: {"text" => "x"}}])
      expect(requests.first["tools"].first.dig("function", "name")).to eq("echo_tool")
      expect(result.transcript.pluck(:role)).to include("tool")
    end

    it "aborts with Llm::Error when the model ignores the exhausted budget" do
      stub_llm(*%w[a b c d e f].map { |text| tool_call_body([["echo_tool", {text: text}]]) })
      budget = Llm::ToolBudget.new(limit: 0)

      expect {
        described_class.new.call(model: model, tools: [EchoTool.new(budget: budget)], budget: budget) { |chat| chat.ask("go") }
      }.to raise_error(Llm::Error, "Too many tool calls (limit 0)") { |error|
        expect(error.tool_calls.size).to eq(3)
        expect(error.transcript).not_to be_empty
      }
    end

    {
      "RubyLLM::Error" => RubyLLM::Error.new("boom"),
      "RubyLLM::ConfigurationError" => RubyLLM::ConfigurationError.new("no key"),
      "RubyLLM::ModelNotFoundError" => RubyLLM::ModelNotFoundError.new("no model"),
      "Timeout::Error" => Timeout::Error.new("slow"),
      "JSON::ParserError" => JSON::ParserError.new("bad json")
    }.each do |label, exception|
      it "wraps #{label} in Llm::Error with cause, transcript and tool_calls" do
        allow_any_instance_of(RubyLLM::Transport::Connection).to receive(:post).and_raise(exception)

        expect { described_class.new.call(model: model, system: "Rules") { |chat| chat.ask("hi") } }
          .to raise_error(Llm::Error, /#{exception.message}/) { |error|
            expect(error.cause).to be_a(exception.class)
            expect(error.transcript.pluck(:role)).to include("system", "user")
            expect(error.tool_calls).to eq([])
          }
      end
    end

    it "re-raises an Llm::Error from the block with the transcript attached" do
      stub_llm(text_body("x"))

      expect { described_class.new.call(model: model) { |chat| chat.ask("hi") && raise(Llm::Error, "invalid") } }
        .to raise_error(Llm::Error, "invalid") { |error| expect(error.transcript.pluck(:role)).to eq(%w[user assistant]) }
    end

    it "times out the block" do
      stub_llm(text_body("x"))

      expect { described_class.new(timeout: 0.05).call(model: model) { sleep 1 } }
        .to raise_error(Llm::Error, /Timeout|Error/) { |error| expect(error.cause).to be_a(Timeout::Error) }
    end
  end
end
