module Support
  class Note < ApplicationRecord
    self.table_name = "support_notes"

    belongs_to :ticket, class_name: "Support::Ticket"
    belongs_to :account, optional: true

    enum :kind, {internal: 0, system: 1, ai: 2}, default: :internal, validate: {allow_nil: false}

    validates :body, presence: true

    # System notes are the audit trail: they cannot be edited, or deleted on their own. They still
    # go away with their ticket (dependent: :destroy sets destroyed_by_association).
    before_update { throw(:abort) if system? }
    before_destroy { throw(:abort) if system? && !destroyed_by_association }

    default_scope { order(created_at: :desc) }
  end
end
