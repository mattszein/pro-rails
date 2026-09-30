class Audience < ApplicationRecord
  has_many :audience_conditions, dependent: :destroy
  has_many :feature_flag_audiences, dependent: :restrict_with_error
  has_many :feature_flags, through: :feature_flag_audiences

  accepts_nested_attributes_for :audience_conditions, allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validate :at_least_one_condition

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :search_name, ->(query) { where("name ILIKE ?", "%#{sanitize_sql_like(query)}%") }

  # Attach count per audience, counting only declared flags. A correlated
  # subquery (not a join) so audiences with zero attachments still appear.
  scope :with_flag_usage, -> {
    declared_flag_ids_sql = FeatureFlag.declared.select(:id).to_sql
    select(
      "audiences.*, (SELECT COUNT(*) FROM feature_flag_audiences ffa " \
      "WHERE ffa.audience_id = audiences.id AND ffa.feature_flag_id IN (#{declared_flag_ids_sql})) " \
      "AS flag_usage_count"
    )
  }

  # Every turned-on condition must match. No conditions -> false, not
  # vacuously true, so a stray empty audience never grants everyone.
  def matches?(account)
    conditions = audience_conditions.to_a
    return false if conditions.empty?

    conditions.all? { |condition| condition.matches?(account) }
  end

  # Builds an unsaved row for every registered condition this audience
  # doesn't already hold, so the form always has one on/off row per
  # declared condition.
  def build_missing_conditions
    existing_keys = audience_conditions.map(&:condition_key)
    AudienceConditions::Registry.all.each do |condition| # rubocop:disable Rails/FindEach
      next if existing_keys.include?(condition.key.to_s)
      audience_conditions.build(condition_key: condition.key.to_s)
    end
  end

  def breadcrumb_title = name

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  private

  def at_least_one_condition
    return if audience_conditions.reject(&:marked_for_destruction?).any?

    errors.add(:base, I18n.t("activerecord.errors.models.audience.attributes.base.at_least_one_condition"))
  end
end
