module Support
  module Ai
    # The user-facing LLM call. Skipped (context.reply nil) in triage_only mode or when triage
    # escalated. FATAL: failures are logged and re-raised so the job retries.
    class Respond
      include Interactor

      delegate :ticket, :playbook, :triage, :trigger, :trigger_message, to: :context

      def call
        return if playbook.triage_only? || triage&.dig(:escalate)

        result = SupportAi::Responder.new(ticket: ticket, playbook: playbook).respond(trigger_message: trigger_message)
        context.reply = result.output
        context.respond_run = RecordRun.call(ticket: ticket, playbook: playbook, trigger: trigger, step: :respond, result: result)
      rescue Llm::Error => e
        RecordRun.call(ticket: ticket, playbook: playbook, trigger: trigger, step: :respond, error: e)
        raise
      end
    end
  end
end
