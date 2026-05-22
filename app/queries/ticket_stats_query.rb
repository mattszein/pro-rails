class TicketStatsQuery
  def self.call(scope: Support::Ticket.all)
    {
      total: scope.count,
      open: scope.open.count,
      by_status: scope.reorder(nil).group(:status).count,
      avg_resolution_hours: scope.where(status: [:finished, :closed]).average(
        "EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600"
      )
    }
  end
end
