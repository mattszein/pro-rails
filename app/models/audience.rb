class Audience < ApplicationRecord
  has_many :audience_conditions, dependent: :destroy
  has_many :feature_flag_audiences
  has_many :feature_flags, through: :feature_flag_audiences

  accepts_nested_attributes_for :audience_conditions, allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validate :at_least_one_condition

  before_destroy :abort_destroy

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :attachable, ->(feature_flag) { active.where.not(id: feature_flag.audiences.select(:id)) }
  scope :search_name, ->(query) { where("name ILIKE ?", "%#{sanitize_sql_like(query)}%") }

  # Attach count per audience, counting only declared flags — a flag whose
  # capability has since been finished no longer counts as a consumer of the
  # audiences it had attached (S21). A correlated subquery rather than a join
  # so audiences with zero attachments still appear (LEFT JOIN would need the
  # "declared" filter in its ON clause, which Rails' `left_joins` cannot
  # express without dropping to raw SQL anyway).
  scope :with_flag_usage, -> {
    declared_flag_ids_sql = FeatureFlag.declared.select(:id).to_sql
    select(
      "audiences.*, (SELECT COUNT(*) FROM feature_flag_audiences ffa " \
      "WHERE ffa.audience_id = audiences.id AND ffa.feature_flag_id IN (#{declared_flag_ids_sql})) " \
      "AS flag_usage_count"
    )
  }

  # Every turned-on condition must match (conjunction) — including one whose
  # condition_key the vocabulary no longer declares, which always answers
  # false (AudienceCondition#matches?). That single rule is what makes a
  # retired condition fail the WHOLE audience rather than being silently
  # skipped (S29): conjunction with a false term is false, with no special
  # case needed here. Runs identically for archived and active audiences
  # (S18) — archiving does not change what this method reads.
  #
  # An audience with no conditions returns false, not vacuously true — S26
  # keeps that state off the form, but role pruning reaches it (S25), and an
  # empty conjunction read as "everyone" would hand a capability to every
  # signed-in account.
  def matches?(account)
    conditions = audience_conditions.to_a
    return false if conditions.empty?

    conditions.all? { |condition| condition.matches?(account) }
  end

  # Deleting a role removes it from every audience whose Roles condition
  # selected it; the deletion is never refused (S25). Skips validation
  # deliberately — an audience left with no conditions is a state the
  # product requires to exist, so the at-least-one-condition rule cannot be
  # allowed to veto a role deletion.
  def self.prune_role(role_id)
    role_id = role_id.to_i

    transaction do
      AudienceCondition.where(condition_key: "roles").find_each do |condition|
        ids = Array(condition.value).map(&:to_i)
        next unless ids.include?(role_id)

        remaining = ids - [role_id]
        if remaining.empty?
          condition.delete
        else
          condition.update_column(:value, remaining)
        end
      end
    end
  end

  def in_use?
    feature_flag_audiences.exists?
  end

  def breadcrumb_title = name

  # Defensive: no operator path calls `destroy`. Archiving is how an audience
  # leaves circulation; `destroy` staying blocked is a guard against a future
  # console session or job reaching it while still attached.
  def destroyable?
    !in_use?
  end

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

  def abort_destroy
    throw(:abort) if in_use?
  end
end
