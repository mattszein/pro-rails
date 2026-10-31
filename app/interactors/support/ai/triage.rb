module Support
  module Ai
    # One structured LLM call. Non-fatal: on failure the run is logged and the organizer
    # continues with the ticket's own category/priority (context.triage stays nil).
    # A retry reuses the triage that already succeeded instead of paying for another call.
    class Triage
      include Interactor

      delegate :ticket, :trigger, to: :context

      def call
        context.triage = previous_output || run_triage
      end

      private

      def previous_output
        ticket.ai_runs.latest_output(:triage)
      end

      def run_triage
        result = SupportAi::Responder.new(ticket: ticket).triage
        RecordRun.call(ticket: ticket, trigger: trigger, step: :triage, result: result)
        result.output
      rescue Llm::Error => e
        RecordRun.call(ticket: ticket, trigger: trigger, step: :triage, error: e)
        nil
      end
    end
  end
end
