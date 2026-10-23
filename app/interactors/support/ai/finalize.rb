module Support
  module Ai
    # Commits the outcome. All LLM work is already done, so the lock is short and DB-only.
    # Under the ticket lock it re-checks that the AI still owns the ticket (an admin may have
    # taken over, or the user may have written again) and otherwise discards the reply.
    # The handoff summary (an LLM call) runs after the lock is released; the ticket is already
    # `handoff_requested` by then, so nothing can race with it.
    class Finalize
      include Interactor

      delegate :ticket, :playbook, :triage, :reply, :trigger_message, to: :context

      def call
        outcome = commit
        finish_handoff(outcome[:reason]) if outcome[:handoff]
      ensure
        Typing.hide(ticket)
      end

      private

      def commit
        outcome = {handoff: false}
        ticket.with_lock do
          next discard if !ticket.ai_analyzing? || superseded?

          reason = handoff_reason
          create_ai_message
          if reason
            ticket.request_ai_handoff!
            outcome = {handoff: true, reason: reason}
          else
            ticket.await_user_reply!
          end
        end
        outcome
      end

      def discard
        (context.handle_run || context.respond_run)&.update!(status: :discarded)
        context.discarded = true
      end

      # A newer human message means its own job will answer. A ticket_created run (no trigger
      # message) is superseded by any human message the user typed while it was working.
      def superseded?
        ticket.conversation.messages.human.where("messages.id > ?", trigger_message&.id || 0).exists?
      end

      def create_ai_message
        content = (handoff_reason ? generic_handoff_message : reply&.dig(:reply).presence)
        return unless content

        ticket.conversation.messages.create!(
          sender: :ai,
          account: nil,
          content: content,
          metadata: {article_ids: reply&.dig(:article_ids) || [], resolution_proposed: reply&.dig(:resolution_proposed) || false}
        )
      end

      # Whenever the pass ends in a handoff the user hears this fixed, localized text instead of
      # the model's reply (no claims, no promises). Nothing in triage_only mode.
      def generic_handoff_message
        return if playbook.triage_only? || !handoff_reason

        I18n.with_locale(message_locale) { I18n.t("support.ai.handoff_message") }
      end

      def message_locale
        language = triage&.dig(:language).to_s
        %w[en es].include?(language) ? language : I18n.locale
      end

      def handoff_reason
        @handoff_reason ||=
          if reply&.dig(:handoff_requested)
            reply[:handoff_reason].presence || "assistant requested a human"
          elsif triage&.dig(:escalate)
            triage[:escalate_reason].presence || "triage escalated"
          elsif playbook.triage_only?
            "playbook is triage only"
          elsif reply && ai_message_count + 1 >= playbook.max_ai_turns
            "maximum AI turns reached"
          end
      end

      def ai_message_count
        ticket.conversation.messages.ai.count
      end

      def finish_handoff(reason)
        HandoffNote.call(ticket: ticket, playbook: playbook, reason: reason) unless context.note_written
      end
    end
  end
end
