class Adminit::AnnouncementQuery < BaseTableQuery
  FILTERS = {
    status: ->(rel, v) { rel.where(status: v) }
  }.freeze

  SORTS = %i[reference status created_at scheduled_at].freeze
end
