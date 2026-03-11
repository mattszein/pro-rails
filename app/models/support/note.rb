module Support
  class Note < ApplicationRecord
    self.table_name = "support_notes"

    belongs_to :ticket, class_name: "Support::Ticket"
    belongs_to :account, optional: true

    enum :kind, {internal: 0, system: 1}, default: :internal, validate: {allow_nil: false}

    validates :body, presence: true

    default_scope { order(created_at: :desc) }
  end
end
