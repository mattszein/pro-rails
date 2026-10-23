require "rails_helper"

RSpec.describe Adminit::AiPlaybookPolicy, type: :policy do
  let(:admin_role) { create(:role, name: "admin") }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:playbook) { create(:ai_playbook) }

  it "uses the support_ai permission resource" do
    expect(described_class::POLICY_RESOURCE).to eq(:support_ai)
    expect(Permission::RESOURCE_REGISTRY[:support_ai]).to eq(9)
  end

  describe "#manage?" do
    it "allows a role with the support_ai permission" do
      create(:permission, resource: :support_ai, roles: [admin_role])
      expect(described_class.new(playbook, user: admin_account)).to be_manage
    end

    it "denies a user without a role" do
      expect(described_class.new(playbook, user: create(:account, :verified))).not_to be_manage
    end

    it "denies a role without the permission" do
      other = create(:account, :verified, role: create(:role, name: "other"))
      expect(described_class.new(playbook, user: other)).not_to be_manage
    end
  end
end
