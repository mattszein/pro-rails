class FeatureFlag < ApplicationRecord
  has_many :feature_flag_audiences, dependent: :destroy
  has_many :audiences, through: :feature_flag_audiences
  has_many :account_entries, class_name: "FeatureFlagAccount", dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validate :key_registered

  before_destroy :abort_destroy

  # No status column: a flag with at least one attached audience or one
  # allowed entry is open. A flag holding only blocked entries grants
  # nobody, so it does not count as open.
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

  # Only rows for keys the registry currently declares — a flag whose
  # capability has since been finished (retired from code) is not "declared",
  # even though its row and access-list history remain (S31).
  scope :declared, -> { where(key: FeatureFlags::Registry.keys.map(&:to_s)) }

  # Insert-ignore a row for every declared key that has none, so the admin
  # index can stay an ordinary relation (sorting, filtering and pagination in
  # SQL) instead of merging registry keys with rows in Ruby. Called from the
  # admin index and nowhere else — the evaluation path performs no writes.
  def self.materialize_declared!
    keys = FeatureFlags::Registry.keys.map(&:to_s)
    return if keys.empty?

    now = Time.current
    insert_all(
      keys.map { |key| {key: key, created_at: now, updated_at: now} },
      unique_by: :index_feature_flags_on_key
    )
  end

  # For one account and one flag, top to bottom (PRODUCT-PLAN "Decision rules"):
  # 1. A blocked account entry always wins (S7).
  # 2. An allowed account entry beats any audience (S6, S8).
  # 3. Any attached audience that matches grants (S2, S4, S5, S10, S12).
  # 4. Otherwise, no (S1, S3, S11).
  #
  # Reads only associations the caller has already loaded (the evaluator
  # preloads audiences and account_entries) — this must never issue its own
  # query, or a page checking several flags multiplies queries per flag.
  def grants?(account)
    entry = account_entries.detect { |e| e.account_id == account.id }
    return false if entry&.blocked?
    return true if entry&.allowed?

    audiences.any? { |audience| audience.matches?(account) }
  end

  def display_name = I18n.t("feature_flags.flags.#{key}.name", default: key)

  def breadcrumb_title = display_name

  private

  def abort_destroy
    throw(:abort)
  end

  def key_registered
    return if key.blank? # presence validation covers this
    return if FeatureFlags::Registry.registered?(key)

    errors.add(:key, :not_registered)
  end
end
