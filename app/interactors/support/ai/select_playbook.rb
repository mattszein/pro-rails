module Support
  module Ai
    # Picks the playbook for this run with the current rules (most specific match, else the default).
    # With no usable playbook the organizer stops: a fresh ticket goes back to `off`; an ongoing
    # conversation is handed to a human (the user is already talking to the assistant).
    class SelectPlaybook
      include Interactor

      delegate :ticket, :trigger, :triage, to: :context

      def call
        context.playbook = Support::AiPlaybook.match_for(ticket, priority: triage&.dig(:priority) || ticket.priority)
        abort_run unless context.playbook
      end

      private

      # No playbook = no instructions, so the AI cannot continue. Get the ticket out of `analyzing`,
      # then stop the organizer (ApplyTriage / Handle / Finalize must not run).
      def abort_run
        reply_pass? ? hand_off_to_human : turn_ai_off
        context.fail!(error: "No AI playbook matched")
      end

      def reply_pass? = trigger == :user_message

      def hand_off_to_human = Fallback.call(ticket: ticket, reason: "no AI playbook available")

      def turn_ai_off
        ticket.disable_ai!
      rescue Support::Ticket::InvalidTransition
        nil # an admin took over meanwhile: nothing left to turn off
      end
    end
  end
end
