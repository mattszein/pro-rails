class FeatureFlag < ApplicationRecord
  # :delete_all (not :destroy): these join rows carry no callbacks, and it
  # keeps a plain `.where(...).delete_all` on the association a real DELETE
  # — with no `dependent:` set at all, Rails nullifies the (non-null)
  # foreign key instead, which raises.
  has_many :feature_flag_audiences, dependent: :delete_all
  has_many :audiences, through: :feature_flag_audiences
  has_many :account_entries, class_name: "FeatureFlagAccount", dependent: :delete_all

  validates :key, presence: true, uniqueness: true
  validate :key_registered

  before_destroy :abort_destroy

  # A flag with no attached audience and no allowed entry grants nobody.
  scope :open_access, -> {
    where(id: FeatureFlagAudience.select(:feature_flag_id))
      .or(where(id: FeatureFlagAccount.allowed.select(:feature_flag_id)))
  }
  scope :empty_access, -> { where.not(id: open_access) }
  scope :search_key, ->(query) { where("key ILIKE ?", "%#{sanitize_sql_like(query)}%") }
  scope :by_access_state, ->(state) {
    case state.to_s
    when "open" then open_access
    when "empty" then empty_access
    else all
    end
  }

  # Only keys the registry currently declares — a retired flag's row and
  # access-list history stay, but it drops out of the admin list.
  scope :declared, -> { where(key: FeatureFlags::Registry.keys.map(&:to_s)) }

  # Insert-ignore a row for every declared key that has none, so the admin
  # index stays an ordinary relation instead of merging registry keys with
  # rows in Ruby.
  def self.materialize_declared!
    keys = FeatureFlags::Registry.keys.map(&:to_s)
    return if keys.empty?

    now = Time.current
    insert_all(
      keys.map { |key| {key: key, created_at: now, updated_at: now} },
      unique_by: :index_feature_flags_on_key
    )
  end

  # Audiences offered to attach: active and not already attached.
  def attachable_audiences
    Audience.active.where.not(id: audiences.select(:id))
  end

  # Block always wins; an explicit allow beats any audience; otherwise any
  # matching attached audience grants. Reads only preloaded associations —
  # never issues its own query, so checking several flags stays cheap.
  def grants?(account)
    entry = account_entries.detect { |e| e.account_id == account.id }
    return false if entry&.blocked?
    return true if entry&.allowed?

    audiences.any? { |audience| audience.matches?(account) }
  end

  def display_name = I18n.t("feature_flags.flags.#{key}.name", default: key)

  def description = I18n.t("feature_flags.flags.#{key}.description", default: nil)

  def breadcrumb_title = display_name

  private

  def abort_destroy
    throw(:abort)
  end

  def key_registered
    return if key.blank? # presence validation covers this

    errors.add(:key, :not_registered) unless FeatureFlags::Registry.registered?(key)
  end
end
