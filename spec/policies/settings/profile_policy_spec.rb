require "rails_helper"

RSpec.describe Settings::ProfilePolicy, type: :policy do
  let(:account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:profile) { create(:profile, account: account) }

  describe "#edit?" do
    it "allows the profile owner" do
      expect(described_class.new(profile, user: account)).to be_edit
    end

    it "denies a different account" do
      expect(described_class.new(profile, user: other_account)).not_to be_edit
    end
  end

  describe "#update?" do
    it "allows the profile owner" do
      expect(described_class.new(profile, user: account)).to be_update
    end

    it "denies a different account" do
      expect(described_class.new(profile, user: other_account)).not_to be_update
    end
  end
end
