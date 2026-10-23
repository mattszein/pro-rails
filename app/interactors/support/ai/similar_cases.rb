module Support
  module Ai
    # Optional, ADMIN-ONLY supplement after Handle: similar past cases (similar_tickets reads
    # other requesters' tickets, so it is never part of the user-facing chat). Writes a second
    # `ai` note. NON-FATAL: a failure is logged as a failed run and the organizer continues.
    # Skipped on a retry once any investigate run (success or failure) exists for the ticket.
    class SimilarCases
      include Interactor

      delegate :ticket, :playbook, :trigger, to: :context

      def call
        return unless playbook.capability?(:similar_tickets)
        return if ticket.ai_runs.investigate.exists?

        result = SupportAi::Responder.new(ticket: ticket, playbook: playbook).investigate
        ticket.notes.create!(account: nil, kind: :ai, body: "Similar past cases: #{result.output}")
        RecordRun.call(ticket: ticket, playbook: playbook, trigger: trigger, step: :investigate, result: result)
      rescue SupportAi::Error => e
        RecordRun.call(ticket: ticket, playbook: playbook, trigger: trigger, step: :investigate, error: e)
      end
    end
  end
end
