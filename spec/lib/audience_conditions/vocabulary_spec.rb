require "rails_helper"

RSpec.describe "the audience condition vocabulary" do
  it "registers the four declared conditions" do
    expect(AudienceConditions::Registry.keys).to contain_exactly(
      :adminit_users, :roles, :verified_users, :registration_age
    )
  end

  # Not an ActiveRecord relation — Registry.all is an in-memory array.
  AudienceConditions::Registry.all.each do |condition| # rubocop:disable Rails/FindEach
    describe ":#{condition.key}" do
      include_examples "a registered audience condition", condition
    end
  end
end
