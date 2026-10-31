module Support
  module Ai
    # Applies only what the playbook allows (auto_set_priority / auto_correct_category), only
    # when the value differs, in one update, with an English system note per change.
    class ApplyTriage
      include Interactor

      delegate :ticket, :playbook, :triage, to: :context

      def call
        return unless triage

        changes = {}
        notes = []
        collect_priority(changes, notes)
        collect_category(changes, notes)
        return if changes.empty?

        ticket.update!(changes)
        notes.each { |body| ticket.notes.create!(account: nil, kind: :system, body: body) }
      end

      private

      def collect_priority(changes, notes)
        return unless playbook.capability?(:auto_set_priority)

        priority = triage[:priority]
        return if priority.nil? || priority == ticket.priority

        notes << "AI set priority #{priority} (was #{ticket.priority}): #{triage[:summary]}"
        changes[:priority] = priority
      end

      def collect_category(changes, notes)
        return unless playbook.capability?(:auto_correct_category)

        category = triage[:category].to_s
        return if category.blank? || category == ticket.category

        notes << "AI changed category to #{category} (was #{ticket.category})"
        changes[:category] = category
      end
    end
  end
end
