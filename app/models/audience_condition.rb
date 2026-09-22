class AudienceCondition < ApplicationRecord
  belongs_to :audience

  validates :condition_key, presence: true, uniqueness: {scope: :audience_id}
  validate :condition_key_registered
  validate :value_conforms_to_vocabulary, if: :registered?

  # The registered vocabulary entry for this row's condition_key, or nil if
  # it is not (or no longer) declared — S29's whole-audience guard reads this
  # to decide whether the audience matches at all.
  def condition
    return nil unless registered?

    AudienceConditions::Registry.fetch(condition_key)
  end

  # Delegates to the registered predicate. Rescues broadly rather than
  # letting a bad predicate lambda — this row's, or a future one's — raise
  # into the evaluation path; a condition that cannot be evaluated must
  # narrow access, never widen it.
  def matches?(account)
    cond = condition
    return false unless cond

    !!cond.predicate.call(account, value)
  rescue
    false
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
