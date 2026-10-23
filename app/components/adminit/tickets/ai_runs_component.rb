module Adminit
  module Tickets
    # "AI activity" panel: the ticket's assistant runs, newest first. Takes the runs as an
    # argument (already loaded by the caller) and never queries.
    class AiRunsComponent < ApplicationViewComponent
      LIMIT = 20
      ERROR_LENGTH = 80
      STATUS_THEMES = {"succeeded" => :green, "failed" => :red, "discarded" => :secondary}.freeze

      option :runs
      option :ticket, default: -> {}

      def sorted_runs
        runs.sort_by { |run| [run.created_at, run.id] }.reverse.first(LIMIT)
      end

      def columns
        cols = [
          column(:step) { |run|
            safe_join([
              t("enums.ai_run.step.#{run.step}"),
              (render(Adminit::Tickets::KbGapComponent.new(ticket: ticket)) if ticket && Adminit::Tickets::KbGapComponent.gap?(run))
            ].compact, " ")
          },
          column(:trigger) { |run| t("enums.ai_run.run_trigger.#{run.run_trigger}") },
          column(:model) { |run| run.model || "-" },
          column(:status) { |run| render(Core::BadgeComponent.new(label: t("enums.ai_run.status.#{run.status}"), theme: status_theme(run), size: :xs)) },
          column(:tokens) { |run| content_tag(:span, tokens(run), class: "text-nowrap") },
          column(:latency) { |run| run.latency_ms || "-" },
          column(:tools) { |run| tool_names(run) },
          column(:error) { |run| error_cell(run) }
        ]
        cols << Core::Table::Column.new(label: t("adminit.tickets.ai_runs.view"), renderer: ->(run) { view_link(run) }) if ticket
        cols
      end

      def status_theme(run)
        STATUS_THEMES.fetch(run.status)
      end

      def tool_names(run)
        Array(run.tool_calls).filter_map { |call| call.is_a?(Hash) ? (call["name"] || call["tool"]) : call.to_s.presence }.join(", ").presence || "-"
      end

      def tokens(run)
        "#{run.input_tokens || "-"} / #{run.output_tokens || "-"}"
      end

      def error_text(run)
        run.error.present? ? truncate(run.error, length: ERROR_LENGTH) : "-"
      end

      private

      def column(key, &renderer)
        Core::Table::Column.new(label: t("adminit.tickets.ai_runs.#{key}"), renderer: renderer)
      end

      def error_cell(run)
        return error_text(run) if run.error.blank?

        render(Core::BadgeComponent.new(label: error_text(run), theme: :red, size: :xs, classes: "normal-case whitespace-normal text-left"))
      end

      def view_link(run)
        render(Core::LinkComponent.new(name: t("adminit.tickets.ai_runs.view"), url: adminit_ticket_ai_run_path(ticket_id: ticket.id, id: run.id), style: :link, html_options: {data: {turbo_frame: "modal"}}))
      end
    end
  end
end
