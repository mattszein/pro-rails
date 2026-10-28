module Support
  class AiRun < ApplicationRecord
    self.table_name = "support_ai_runs"

    belongs_to :ticket, class_name: "Support::Ticket"
    belongs_to :playbook, class_name: "Support::AiPlaybook", optional: true

    enum :run_trigger, {ticket_created: 0, user_message: 1, draft_reply: 2, idle_reminder: 3, fallback: 4}, validate: {allow_nil: false}
    # `investigate` is legacy (the admin-only similar-cases pass was removed); kept so old rows load.
    enum :step, {triage: 0, investigate: 1, respond: 2, draft: 3, handle: 4}, validate: {allow_nil: false}
    enum :status, {succeeded: 0, failed: 1, discarded: 2}, validate: {allow_nil: false}

    validates :run_trigger, :step, :status, presence: true

    scope :recent, ->(limit = nil) { order(created_at: :desc, id: :desc).limit(limit) }

    # Output of the newest succeeded run of `step` (indifferent-access Hash), or nil. Callable on
    # a ticket's association: `ticket.ai_runs.latest_output(:triage)`.
    def self.latest_output(step)
      succeeded.where(step: step).order(:id).last&.output&.with_indifferent_access.presence
    end
  end
end
