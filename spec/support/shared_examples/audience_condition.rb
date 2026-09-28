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
end
