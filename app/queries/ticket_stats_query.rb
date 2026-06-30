class TicketStatsQuery
  def self.call(scope: Support::Ticket.all)
    {
      total: scope.count,
      open: scope.open.count,
      in_progress: scope.in_progress.count,
      resolved: scope.where(status: [:finished, :closed]).count,
      by_status: scope.reorder(nil).group(:status).count
    }
  end
end
