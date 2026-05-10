class Adminit::AccountQuery < BaseTableQuery
  FILTERS = {
    status: ->(rel, v) { rel.where(status: v) },
    role_id: ->(rel, v) { rel.where(role_id: v) },
    search: ->(rel, v) { rel.where("email ILIKE ?", "%#{Account.sanitize_sql_like(v)}%") }
  }.freeze

  SORTS = %i[email created_at status].freeze

end
