module Support
  module Ai
    # Writes a Support::AiRun audit row from a SupportAi::Result (success) or an error (failure).
    module RecordRun
      module_function

      def call(ticket:, trigger:, step:, playbook: nil, result: nil, error: nil, status: nil)
        status ||= error ? :failed : :succeeded
        Support::AiRun.create!(
          ticket: ticket,
          playbook: playbook,
          run_trigger: trigger,
          step: step,
          status: status,
          model: result&.model,
          input_tokens: result&.input_tokens,
          output_tokens: result&.output_tokens,
          latency_ms: result&.latency_ms,
          tool_calls: result&.tool_calls || error_attr(error, :tool_calls),
          transcript: result&.transcript || error_attr(error, :transcript),
          output: output_for(result),
          error: error&.then { |e| e.respond_to?(:message) ? e.message : e.to_s }
        )
      end

      def error_attr(error, name)
        error.respond_to?(name) ? Array(error.public_send(name)) : []
      end

      def output_for(result)
        case result&.output
        when nil then {}
        when Hash then result.output
        else {text: result.output.to_s}
        end
      end
    end
  end
end
