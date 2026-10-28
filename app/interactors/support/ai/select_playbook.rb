module Support
  module Ai
    # Picks the playbook for this run with the current rules (most specific match, else the default).
    # With no usable playbook the organizer stops: a fresh ticket goes back to `off`; an ongoing
    # conversation is handed to a human (the user is already talking to the assistant).
    class SelectPlaybook
      include Interactor

      delegate :ticket, :trigger, :triage, to: :context

      def call
        playbook = Support::AiPlaybook.match_for(ticket, priority: triage&.dig(:priority) || ticket.priority)
        return stop_without_playbook unless playbook

        context.playbook = playbook
      end

      private

      def stop_without_playbook
        if trigger.to_s == "user_message"
          Fallback.call(ticket: ticket, reason: "no AI playbook available")
        else
          disable_ai
        end
        context.fail!(error: "No AI playbook matched")
      end

      def disable_ai
        ticket.with_lock { ticket.disable_ai! if ticket.ai_analyzing? }
      end
    end
  end
end
