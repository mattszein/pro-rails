class Support::TicketQuery < BaseTableQuery
  FILTERS = {
    status: ->(rel, v) { rel.where(status: v) },
    category: ->(rel, v) { rel.where(category: v) },
    search: ->(rel, v) { rel.where("title ILIKE ?", "%#{Support::Ticket.sanitize_sql_like(v)}%") }
  }.freeze

  SORTS = %i[title status created_at].freeze

end
