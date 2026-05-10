class Adminit::TicketQuery < BaseTableQuery
  FILTERS = {
    status: ->(rel, v) { rel.where(status: v) },
    search: ->(rel, v) { rel.where("title ILIKE ?", "%#{Support::Ticket.sanitize_sql_like(v)}%") }
  }.freeze

  SORTS = %i[title status priority created_at].freeze

end
