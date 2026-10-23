module Adminit
  module Tickets
    # Read-only view of one AI run: header facts, error, the recorded transcript, tool calls and
    # output. Takes an already-loaded run and never queries. All text is rendered escaped.
    class AiRunTranscriptComponent < ApplicationViewComponent
      STATUS_THEMES = {"succeeded" => :green, "failed" => :red, "discarded" => :secondary}.freeze
      ROLE_THEMES = {"system" => :secondary, "developer" => :secondary, "user" => :primary, "assistant" => :green, "tool" => :orange}.freeze

      option :run
      option :playbook_name, default: -> {}

      def status_theme
        STATUS_THEMES.fetch(run.status)
      end

      def entries
        @entries ||= Array(run.transcript).select { |entry| entry.is_a?(Hash) }
      end

      def role_of(entry)
        entry["role"].to_s
      end

      def role_label(entry)
        role = role_of(entry)
        t("adminit.tickets.ai_runs.roles.#{role}", default: role.presence || "?")
      end

      def role_theme(entry)
        ROLE_THEMES.fetch(role_of(entry), :secondary)
      end

      def tool_calls_of(entry)
        Array(entry["tool_calls"]).select { |call| call.is_a?(Hash) }
      end

      # Maps tool_call_id -> tool name from the assistant entries, to label tool results.
      def tool_names_by_id
        @tool_names_by_id ||= entries.flat_map { |entry| tool_calls_of(entry) }.to_h { |call| [call["id"], call["name"]] }
      end

      def tool_result_label(entry)
        id = entry["tool_call_id"]
        name = tool_names_by_id[id]
        [name, id].compact_blank.join(" / ").presence
      end

      def tokens
        "#{run.input_tokens || "-"} / #{run.output_tokens || "-"}"
      end

      def pretty(value)
        JSON.pretty_generate(value)
      end

      def run_tool_calls
        Array(run.tool_calls)
      end

      def output?
        run.output.present?
      end
    end
  end
end
