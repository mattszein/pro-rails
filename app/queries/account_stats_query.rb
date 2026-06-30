class AccountStatsQuery
  MONTHS = 6

  def self.call
    {
      total: Account.count,
      verified: Account.verified.count,
      active_sessions: AccountRememberKey.count,
      by_month: by_month
    }
  end

  def self.by_month
    months = MONTHS.times.map { |i| Time.zone.today.beginning_of_month - i.months }.reverse
    months.index_with { |month| Account.where(created_at: month.all_month).count }
  end
end
