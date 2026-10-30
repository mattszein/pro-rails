module Support
  module Ai
    # The main LLM call: ONE chat that writes the internal note (max 1,200 chars -> `ai` note when the
    # playbook has investigate_note) and then the reply to the user. context.reply stays nil in
    # triage_only mode or when triage escalated (only the note turn runs). The single `ai` note
    # also gets two deterministic lines built by code (never by or for the model). FATAL: failures are logged and re-raised so
    # the job retries. The note is created only after the whole Result is obtained, so a retry
    # after a failure can never leave a duplicate.
    class Handle
      include Interactor

      NOTE_LIMIT = 1_200
      SIMILAR_LIMIT = 5
      # A leading "Internal note (for admin):" style label the model sometimes adds despite the prompt.
      LEADING_LABEL = /\A[\s*_#]*(?:internal\s+)?note(?:\s*\([^)\n]*\))?[\s*_]*:[\s*_]*/i

      delegate :ticket, :playbook, :triage, :trigger, :trigger_message, to: :context

      def call
        reply = !playbook.triage_only? && !triage&.dig(:escalate)
        result = SupportAi::Responder.new(ticket: ticket, playbook: playbook).handle(triage: triage, reply: reply, trigger_message: trigger_message)

        write_note(result.output) if playbook.capability?(:investigate_note)
        context.reply = reply ? result.output : nil
        context.handle_run = RecordRun.call(ticket: ticket, playbook: playbook, trigger: trigger, step: :handle, result: result)
      rescue Llm::Error => e
        RecordRun.call(ticket: ticket, playbook: playbook, trigger: trigger, step: :handle, error: e)
        raise
      end

      private

      # ONE note per pass: the model's short findings plus a deterministic help-center line.
      def write_note(output)
        findings = strip_label(output[:findings].to_s).truncate(NOTE_LIMIT, omission: "…")
        lines = [findings, help_center_line(output[:article_ids]), similar_tickets_line]
        ticket.notes.create!(account: nil, kind: :ai, body: lines.compact_blank.join("\n"))
        context.note_written = true
      end

      def strip_label(text)
        text.sub(LEADING_LABEL, "").strip
      end

      # ADMIN-ONLY and deterministic: other requesters' finished tickets with a similar title
      # (title and month only). Runs no LLM and never enters a prompt.
      def similar_tickets_line
        return unless playbook.capability?(:similar_tickets)

        terms = ticket.title.to_s.scan(/[[:alnum:]]{3,}/).first(5)
        similar = Support::Ticket.resolved_similar_to(ticket, terms: terms, limit: SIMILAR_LIMIT).to_a
        return if similar.empty?

        "Similar resolved tickets: " + similar.map { |past| "##{past.id} #{past.title.to_s.truncate(80)} (#{past.created_at.strftime("%Y-%m")})" }.join(", ")
      end

      # Deterministic system signal (English, not model prose).
      def help_center_line(article_ids)
        titles = Support::Article.where(id: Array(article_ids)).pluck(:title)
        titles.any? ? "Help center: #{titles.join(", ")}" : "Help center: no article answered this."
      end
    end
  end
end
