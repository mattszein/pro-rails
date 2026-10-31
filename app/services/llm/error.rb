module Llm
  # Raised by Llm::Runner (and by the code inside its block) when a call cannot produce a usable
  # result: provider error, timeout, unparsable or invalid structured output, empty reply, too many
  # tool calls. The original exception, when there is one, is available as `cause`.
  #
  # `transcript` and `tool_calls` carry what the chat did before failing (attached by
  # Llm::Runner) so a failed audit row can still show it. Both default to [].
  class Error < StandardError
    attr_accessor :transcript, :tool_calls

    def initialize(message = nil, transcript: [], tool_calls: [])
      super(message)
      @transcript = transcript
      @tool_calls = tool_calls
    end
  end
end
