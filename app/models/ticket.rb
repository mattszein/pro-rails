class Ticket < ApplicationRecord
  belongs_to :created, class_name: "Account", optional: true
  belongs_to :assigned, class_name: "Account", optional: true
  enum :status, {open: 0, in_progress: 1, closed: 2}, default: :open, validate: {allow_nil: false}
  validates :title, :description, :status, :created_id, presence: true

  broadcasts_to ->(ticket) { "admin_tickets" },
    partial: "adminit/tickets/ticket_table",
    target: "admin_tickets"

  after_update_commit do |ticket|
    # For the individual show page
    broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(ticket, "admin"),
      target: ActionView::RecordIdentifier.dom_id(ticket, "admin"),
      partial: "adminit/tickets/ticket"

    # For the admin list page
    broadcast_replace_later_to "admin_tickets",
      target: ActionView::RecordIdentifier.dom_id(ticket, "admin"),
      partial: "adminit/tickets/ticket_table"
  end
  default_scope { order(priority: :desc, created_at: :desc) }
end
