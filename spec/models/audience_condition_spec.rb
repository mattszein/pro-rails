require "rails_helper"

RSpec.describe AudienceCondition, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:audience) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:condition_key) }

    it "validates uniqueness of condition_key scoped to audience" do
      # Not `create(:audience)` — its default callback already adds an
      # adminit_users condition, which would collide with this one.
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "adminit_users", value: true)
      audience.save!

      duplicate = build(:audience_condition, audience: audience, condition_key: "adminit_users")
      expect(duplicate).not_to be_valid
    end

    it "allows the same condition_key on a different audience" do
      first_audience = build(:audience, :without_condition)
      first_audience.audience_conditions.build(condition_key: "adminit_users", value: true)
      first_audience.save!

      other_audience = build(:audience, :without_condition)
      other_audience.audience_conditions.build(condition_key: "verified_users", value: true)
      other_audience.save!

      expect(build(:audience_condition, audience: other_audience, condition_key: "adminit_users")).to be_valid
    end

    # S28 — a condition the vocabulary does not declare is not saved.
    describe "condition_key registration" do
      it "is invalid when condition_key is not declared in the vocabulary" do
        condition = build(:audience_condition, condition_key: "not_a_real_condition", value: true)
        expect(condition).not_to be_valid
        expect(condition.errors[:condition_key]).to be_present
      end

      it "is valid for each of the four declared conditions" do
        expect(build(:audience_condition, :adminit_users)).to be_valid
        expect(build(:audience_condition, :roles, value: [1])).to be_valid
        expect(build(:audience_condition, :verified_users)).to be_valid
        expect(build(:audience_condition, :registration_age)).to be_valid
      end
    end

    # S27 — a condition turned on needs a value shaped for its type.
    describe "value conformance" do
      it "rejects a non-boolean value for a :boolean condition" do
        condition = build(:audience_condition, :adminit_users, value: "yes")
        expect(condition).not_to be_valid
        expect(condition.errors[:value]).to be_present
      end

      it "rejects false for an :affirmative condition — there is no false" do
        condition = build(:audience_condition, :verified_users, value: false)
        expect(condition).not_to be_valid
      end

      it "rejects an empty array for an :id_list condition" do
        condition = build(:audience_condition, :roles, value: [])
        expect(condition).not_to be_valid
      end

      it "rejects a duration with an unlisted unit" do
        condition = build(:audience_condition, :registration_age, value: {"amount" => 1, "unit" => "fortnights"})
        expect(condition).not_to be_valid
      end

      it "accepts a duration with a declared unit" do
        condition = build(:audience_condition, :registration_age, value: {"amount" => 2, "unit" => "months"})
        expect(condition).to be_valid
      end

      it "does not run the value check when condition_key is unregistered — that error stands alone" do
        condition = build(:audience_condition, condition_key: "not_a_real_condition", value: true)
        condition.valid?
        expect(condition.errors[:value]).to be_empty
      end
    end
  end

  describe "#condition" do
    it "returns the registered vocabulary entry" do
      condition = build(:audience_condition, :adminit_users)
      expect(condition.condition.key).to eq(:adminit_users)
    end

    it "returns nil for an unregistered condition_key" do
      condition = build(:audience_condition, condition_key: "not_a_real_condition", value: true)
      expect(condition.condition).to be_nil
    end
  end

  describe "#matches?" do
    it "delegates to the registered predicate" do
      account = create(:account, :with_role)
      condition = build(:audience_condition, :adminit_users, value: true)

      expect(condition.matches?(account)).to be true
    end

    it "returns false when the predicate does not hold" do
      account = create(:account) # no role -> adminit_access? is false
      condition = build(:audience_condition, :adminit_users, value: true)

      expect(condition.matches?(account)).to be false
    end

    it "returns false for an unregistered condition_key rather than raising" do
      condition = build(:audience_condition, condition_key: "not_a_real_condition", value: true)
      account = create(:account)

      expect(condition.matches?(account)).to be false
    end

    it "rescues a predicate that raises and returns false, never widening access" do
      account = create(:account)

      with_audience_condition(:broken_condition, type: :boolean, accepts: [true, false],
        predicate: ->(acct, value) { raise "boom" }) do
        condition = build(:audience_condition, condition_key: "broken_condition", value: true)
        expect(condition.matches?(account)).to be false
      end
    end
  end
end
