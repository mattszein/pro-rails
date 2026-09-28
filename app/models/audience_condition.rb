class AudienceCondition < ApplicationRecord
  belongs_to :audience

  validates :condition_key, presence: true, uniqueness: {scope: :audience_id}
  validate :condition_key_registered
  validate :value_conforms_to_vocabulary, if: :registered?

  # The registered vocabulary entry for this row, or nil if the key is not
  # (or no longer) declared.
  def condition
    return nil unless registered?

    AudienceConditions::Registry.fetch(condition_key)
  end

  # A condition that cannot be evaluated must narrow access, never widen it.
  def matches?(account)
    cond = condition
    return false unless cond

    !!cond.predicate.call(account, value)
  rescue => e
    Rails.logger.error("[AudienceCondition] #{condition_key} predicate failed: #{e.class}: #{e.message}")
    false
  end

  # For an :id_list condition, the actual referenced records (e.g. the Role
  # rows a "roles" condition points at), resolved through the model the
  # vocabulary named rather than the vocabulary knowing about it directly.
  def referenced_records
    return [] unless condition&.type == :id_list

    condition.accepts.constantize.where(id: Array(value))
  end

  private

  def registered?
    condition_key.present? && AudienceConditions::Registry.registered?(condition_key)
  end

  def condition_key_registered
    return if condition_key.blank? # presence validation covers this
    return if AudienceConditions::Registry.registered?(condition_key)

    errors.add(:condition_key, :not_registered)
  end

  def value_conforms_to_vocabulary
    return if AudienceConditions::VocabularyValidator.valid?(condition, value)

    errors.add(:value, :invalid)
  end
end
