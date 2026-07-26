class Account < ApplicationRecord
  include Rodauth::Rails.model
  include Account::Notifiable

  enum :status, {unverified: 1, verified: 2, closed: 3}
  belongs_to :role, optional: true
  has_one :profile, dependent: :destroy

  after_create :create_default_profile

  scope :search_by_email, ->(query) { where("email ILIKE ?", "%#{sanitize_sql_like(query)}%") }
  scope :not_in_role, ->(role) { where.not(role_id: role.id).or(where(role_id: nil)) }
  scope :assignable, -> { where.not(role_id: nil).order(:email) }

  DASHBOARD_STATS_MONTHS = 6

  # Stats for the adminit dashboard accounts analytics widget.
  def self.dashboard_stats
    months = DASHBOARD_STATS_MONTHS.times.map { |i| Time.zone.now.beginning_of_month - i.months }.reverse
    counts_by_month = where(created_at: months.first..)
      .group("date_trunc('month', created_at)")
      .count
      .transform_keys { |key| key.to_date.beginning_of_month }
    by_month = months.index_with { |month| counts_by_month[month.to_date] || 0 }

    {
      total: count,
      verified: verified.count,
      active_sessions: AccountRememberKey.where(deadline: Time.current..).count,
      registered_this_month: by_month.values.last,
      by_month: by_month
    }
  end

  def adminit_access?
    role.present?
  end

  def breadcrumb_title = profile&.username || email

  private

  def create_default_profile
    create_profile!
  end
end
