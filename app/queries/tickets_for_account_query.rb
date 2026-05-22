class TicketsForAccountQuery
  def self.call(account:, limit: 10)
    Support::Ticket
      .where(assigned: account)
      .open
      .order(updated_at: :desc)
      .limit(limit)
  end
end
