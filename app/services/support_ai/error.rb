module SupportAi
  # Raised by every SupportAi service when a step cannot produce a usable result
  # (provider error, timeout, unparsable or invalid structured output, empty reply).
  # The original exception, when there is one, is available as `cause`.
  #
  # `transcript` and `tool_calls` carry what the chat did before failing (attached by
  # Responder#run_step) so the failed AiRun still shows it. Both default to [].
  class Error < StandardError
    attr_accessor :transcript, :tool_calls

    def initialize(message = nil, transcript: [], tool_calls: [])
      super(message)
      @transcript = transcript
      @tool_calls = tool_calls
    end
  end
end
