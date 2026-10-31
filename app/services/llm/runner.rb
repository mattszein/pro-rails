module Llm
  # One reusable way to talk to an LLM through RubyLLM. Generic: knows nothing about Support or
  # Avatar. Builds the chat, runs the caller's block (which performs the asks and returns the
  # domain output), measures tokens and latency, and returns an Llm::Result.
  #
  #   runner = Llm::Runner.new(timeout: 60, temperature: 0.2)
  #   result = runner.call(model: "openai/gpt-oss-120b:free", system: "Be terse.") do |chat|
  #     chat.ask("Say hi").content
  #   end
  #   result.output # => "Hi."
  #
  # Model ids are OpenRouter ids (including ":free" variants that rotate faster than ruby_llm's
  # bundled registry), so the registry lookup is skipped.
  #
  # Errors: ANY Llm::Error (raised by the block, the tool-call backstop, or wrapped from
  # RubyLLM::Error / ConfigurationError / ModelNotFoundError / Timeout::Error / JSON::ParserError)
  # leaves with the chat transcript and recorded tool calls attached. Wrapped errors keep the
  # original as `cause`. Never writes to the database; callers persist.
  class Runner
    DEFAULT_TIMEOUT = 120
    DEFAULT_PROVIDER = :openrouter

    def initialize(timeout: DEFAULT_TIMEOUT, temperature: nil, provider: DEFAULT_PROVIDER)
      @timeout = timeout
      @temperature = temperature
      @provider = provider
    end

    # model:  - model id.
    # system: - system instructions (skipped when nil).
    # tools:  - RubyLLM::Tool instances (usually Llm::Tools::Base sharing `budget`).
    # schema: - structured-output schema for RubyLLM's with_schema (optional).
    # budget: - Llm::ToolBudget (or subclass) shared by the tools; its calls land in the Result.
    # The block receives the RubyLLM chat and its return value becomes Result#output.
    def call(model:, system: nil, tools: [], schema: nil, budget: ToolBudget.new)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      chat = nil
      chat = build_chat(model, system, tools, schema, budget)

      output = Timeout.timeout(timeout) { yield chat }

      usage = chat.tokens
      Result.new(
        output: output,
        model: model,
        input_tokens: usage.input.to_i,
        output_tokens: usage.output.to_i,
        latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
        tool_calls: budget.calls,
        transcript: Transcript.build(chat.messages)
      )
    rescue Error => e
      raise capture(e, chat, budget)
    rescue RubyLLM::Error, RubyLLM::ConfigurationError, RubyLLM::ModelNotFoundError, Timeout::Error, JSON::ParserError => e
      raise capture(Error.new("#{e.class.name.demodulize}: #{e.message}"), chat, budget)
    end

    private

    attr_reader :timeout, :temperature, :provider

    def capture(error, chat, budget)
      error.transcript = chat ? Transcript.build(chat.messages) : []
      error.tool_calls = budget.calls
      error
    end

    def build_chat(model, system, tools, schema, budget)
      chat = RubyLLM.chat(model: model, provider: provider, assume_model_exists: true)
      chat.with_instructions(system) if system
      chat.with_temperature(temperature) unless temperature.nil?
      chat.with_tools(*tools) if tools.any?
      chat.with_schema(schema) if schema
      # Records every attempted call; tools answer with a limit message once the budget is spent
      # (see Llm::Tools::Base#call). This only aborts if the model ignores that and keeps calling.
      chat.before_tool_call do |tool_call|
        raise Error, "Too many tool calls (limit #{budget.limit})" if budget.backstop_hit?

        budget.record(tool_call.name, tool_call.arguments)
      end
      chat
    end
  end
end
