module SupportAi
  # What a Responder step returns.
  #
  # output     - Hash (symbolized keys) for structured steps (triage, respond), String for free text
  #              (investigate, summarize).
  # model      - OpenRouter model id actually used.
  # input_tokens / output_tokens - aggregate usage across every provider call of the step (Integer).
  # latency_ms - wall clock for the whole step, tool loop included.
  # tool_calls - [{name:, arguments:}] for every tool call the model made.
  # transcript - [{role:, content:, tool_calls:, tool_call_id:}] every message of the chat
  #              (see SupportAi::Transcript); stored on the AiRun.
  Result = Data.define(:output, :model, :input_tokens, :output_tokens, :latency_ms, :tool_calls, :transcript)
end
