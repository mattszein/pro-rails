require "rails_helper"

RSpec.describe FeatureFlagAccount, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:feature_flag) }
    it { is_expected.to belong_to(:account) }
  end

  it { is_expected.to define_enum_for(:access).with_values(blocked: 0, allowed: 1) }

  describe "validations" do
    it "requires access to be set" do
      entry = build(:feature_flag_account, access: nil)
      expect(entry).not_to be_valid
      expect(entry.errors[:access]).to be_present
    end

    it "validates uniqueness of account scoped to feature_flag" do
      flag = create(:feature_flag)
      account = create(:account)
      create(:feature_flag_account, feature_flag: flag, account: account)

      duplicate = build(:feature_flag_account, feature_flag: flag, account: account)
      expect(duplicate).not_to be_valid
    end

    it "allows the same account on a different flag" do
      account = create(:account)
      create(:feature_flag_account, account: account)

      expect(build(:feature_flag_account, account: account)).to be_valid
    end
  end
end
