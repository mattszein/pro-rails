module Support
  module Ai
    # Applies only what the playbook allows (auto_set_priority / auto_correct_category), only
    # when the value differs, and leaves an English system note per change.
    class ApplyTriage
      include Interactor

      delegate :ticket, :playbook, :triage, to: :context

      def call
        return unless triage

        apply_priority
        apply_category
      end

      private

      def apply_priority
        return unless playbook.capability?(:auto_set_priority)

        priority = triage[:priority]
        return if priority.nil? || priority == ticket.priority

        previous = ticket.priority
        ticket.update!(priority: priority)
        note("AI set priority #{priority} (was #{previous}): #{triage[:summary]}")
      end

      def apply_category
        return unless playbook.capability?(:auto_correct_category)

        category = triage[:category].to_s
        return if category.blank? || category == ticket.category

        previous = ticket.category
        ticket.update!(category: category)
        note("AI changed category to #{category} (was #{previous})")
      end

      def note(body)
        ticket.notes.create!(account: nil, kind: :system, body: body)
      end
    end
  end
end
