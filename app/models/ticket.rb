class Ticket < ApplicationRecord
  belongs_to :created, class_name: "Account", optional: true
  belongs_to :assigned, class_name: "Account", optional: true
  enum :status, {open: 0, in_progress: 1, closed: 2}, default: :open, validate: {allow_nil: false}
  validates :title, :description, :priority, :status, :created_id, presence: true

  broadcasts_to ->(ticket) { "tickets" }, partial: "adminit/tickets/ticket_table"
  after_update_commit ->(ticket) { broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(ticket), target: ActionView::RecordIdentifier.dom_id(ticket), partial: "adminit/tickets/ticket" }

  default_scope { order(priority: :desc, created_at: :desc) }
end
