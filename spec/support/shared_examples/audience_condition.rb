# Runs against every entry in AudienceConditions::Registry (see
# spec/lib/audience_conditions/vocabulary_spec.rb), so a newly registered
# condition is covered the moment it is declared. Names no condition key —
# everything here is driven by `condition.type` and `condition.accepts`.
RSpec.shared_examples "a registered audience condition" do |condition|
  it "has a label and hint translated in both locales" do
    %i[en es].each do |locale|
      I18n.with_locale(locale) do
        expect(I18n.t("audience_conditions.#{condition.key}.label", default: nil)).to be_present
        expect(I18n.t("audience_conditions.#{condition.key}.hint", default: nil)).to be_present
      end
    end
  end

  if [:boolean, :affirmative].include?(condition.type)
    it "translates every value it declares, in both locales" do
      condition.accepts.each do |value|
        %i[en es].each do |locale|
          I18n.with_locale(locale) do
            key = "audience_conditions.#{condition.key}.values.#{value}"
            expect(I18n.t(key, default: nil)).to be_present
          end
        end
      end
    end
  end

  if condition.type == :duration
    it "translates every unit it declares, in both locales" do
      condition.accepts.each do |unit|
        %i[en es].each do |locale|
          I18n.with_locale(locale) do
            key = "audience_conditions.#{condition.key}.units.#{unit}"
            expect(I18n.t(key, default: nil)).to be_present
          end
        end
      end
    end
  end

  it "accepts a value shaped for its type and rejects one that is not" do
    valid_value = AudienceConditions::TestFixtures.valid_value_for(condition)
    invalid_value = AudienceConditions::TestFixtures.invalid_value_for(condition)

    expect(AudienceConditions::VocabularyValidator.valid?(condition, valid_value)).to be true
    expect(AudienceConditions::VocabularyValidator.valid?(condition, invalid_value)).to be false
  end

  # The `scope` slot raises NotImplementedError for every condition in this
  # milestone (TECH-PLAN §3.1) — pending, not skipped, so the moment a real
  # scope is written this activates on its own: an implementation that
  # disagrees with its predicate keeps the example pending (it still fails,
  # as expected), but one that agrees flips it to an unexpected pass, which
  # RSpec reports as a failure until the `pending` line is removed.
  it "keeps predicate and scope in agreement over a fixture set" do
    pending "scope not implemented for :#{condition.key} (TECH-PLAN §3.1)"

    accounts = AudienceConditions::TestFixtures.sample_accounts
    value = AudienceConditions::TestFixtures.valid_value_for(condition)

    predicate_matches = accounts.select { |account| condition.predicate.call(account, value) }
    scope_matches = condition.scope.call(Account.where(id: accounts.map(&:id)), value).to_a

    expect(scope_matches).to match_array(predicate_matches)
  end
end
