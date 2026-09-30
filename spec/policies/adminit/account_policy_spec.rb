require "rails_helper"

RSpec.describe Adminit::AccountPolicy, type: :policy do
  let(:target) { create(:account, :verified) }

  describe "#search?" do
    it "allows a role with the account permission" do
      role = create(:role)
      create(:permission, resource: :account, roles: [role])
      user = create(:account, :verified, role: role)

      expect(described_class.new(target, user: user)).to be_search
    end

    it "allows a role with the role permission" do
      role = create(:role)
      create(:permission, resource: :role, roles: [role])
      user = create(:account, :verified, role: role)

      expect(described_class.new(target, user: user)).to be_search
    end

    it "allows a role with the feature_flag permission" do
      role = create(:role)
      create(:permission, resource: :feature_flag, roles: [role])
      user = create(:account, :verified, role: role)

      expect(described_class.new(target, user: user)).to be_search
    end

    it "denies a role with none of those permissions" do
      role = create(:role)
      create(:permission, resource: :ticket, roles: [role])
      user = create(:account, :verified, role: role)

      expect(described_class.new(target, user: user)).not_to be_search
    end

    it "denies a user with no role" do
      user = create(:account, :verified)
      expect(described_class.new(target, user: user)).not_to be_search
    end
  end
end
