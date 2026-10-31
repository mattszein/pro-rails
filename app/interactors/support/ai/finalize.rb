module Support
  module Ai
    # Commits the outcome. All LLM work is already done, so the lock is short and DB-only.
    # Under the ticket lock it re-checks that the AI still owns the ticket (an admin may have
    # taken over, or the user may have written again) and otherwise discards the reply.
    # It is the only writer of the pass's `ai` note: Handle's context.note_body, plus the handoff
    # reason when the pass ends in a handoff (no LLM call). A discarded pass keeps the findings
    # note, marked as not sent.
    class Finalize
      include Interactor

      NOT_SENT_LINE = "Reply not sent: the ticket changed while the assistant was working."

      delegate :ticket, :playbook, :triage, :reply, :note_body, to: :context

      def call
        ticket.with_lock do
          owned? ? commit : discard
        end
      end

      private

      def owned?
        ticket.ai_analyzing?
      end

      def commit
        write_note(handoff_reason && "AI handoff: #{handoff_reason}")
        create_ai_message
        handoff_reason ? ticket.request_ai_handoff! : ticket.await_user_reply!
      end

      def discard
        write_note(NOT_SENT_LINE) if context.note_body.present?
        (context.handle_run || context.respond_run)&.update!(status: :discarded)
        context.discarded = true
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

      def write_note(line = nil)
        body = [note_body, line].compact_blank.join("\n")
        ticket.notes.create!(account: nil, kind: :ai, body: body) if body.present?
      end
    end
  end
end
