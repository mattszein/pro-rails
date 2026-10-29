module Support
  module Ai
    # Writes a Support::AiRun audit row from a Llm::Result (success) or an error (failure).
    module RecordRun
      module_function

      def call(ticket:, trigger:, step:, playbook: nil, result: nil, error: nil, status: nil)
        status ||= error ? :failed : :succeeded
        Support::AiRun.create!(
          ticket: ticket,
          playbook: playbook,
          playbook_snapshot: snapshot_for(playbook),
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

      # Frozen copy of the rules the run used, so later playbook edits or deletion do not rewrite history.
      def snapshot_for(playbook)
        return {} unless playbook

        {
          name: playbook.name,
          mode: playbook.mode,
          capabilities: playbook.capabilities,
          instructions: playbook.instructions,
          max_ai_turns: playbook.max_ai_turns,
          idle_reminder_after_hours: playbook.idle_reminder_after_hours,
          idle_handoff_after_hours: playbook.idle_handoff_after_hours,
          categories: playbook.category_keys,
          min_priority: playbook.min_priority,
          max_priority: playbook.max_priority,
          audience: playbook.audience&.name,
          is_default: playbook.is_default
        }
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
