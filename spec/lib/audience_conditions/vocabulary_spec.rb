require "rails_helper"

RSpec.describe "the audience condition vocabulary" do
  it "registers the four declared conditions" do
    expect(AudienceConditions::Registry.keys).to contain_exactly(
      :adminit_users, :roles, :verified_users, :registration_age
    )
  end

  describe ".duration_from" do
    it "rebuilds a calendar duration from a known unit" do
      expect(AudienceConditions::Vocabulary.duration_from({"amount" => "2", "unit" => "years"})).to eq(2.years)
    end

    it "rejects a unit outside the declared set" do
      expect { AudienceConditions::Vocabulary.duration_from({"amount" => "1", "unit" => "to_s"}) }
        .to raise_error(ArgumentError, /unknown duration unit/)
    end
  end

  # Not an ActiveRecord relation — Registry.all is an in-memory array.
  AudienceConditions::Registry.all.each do |condition| # rubocop:disable Rails/FindEach
    describe ":#{condition.key}" do
      include_examples "a registered audience condition", condition
    end
  end
end
