require "rails_helper"

RSpec.describe Adminit::DashboardPolicy, type: :policy do
  let(:admin_role) { create(:role, name: "admin") }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:regular_account) { create(:account, :verified) }

  describe "#show?" do
    context "when user has adminit access" do
      let(:policy) { described_class.new(:dashboard, user: admin_account) }

      it "allows access" do
        expect(policy).to be_show
      end
    end

    context "when user has no role" do
      let(:policy) { described_class.new(:dashboard, user: regular_account) }

      it "denies access" do
        expect(policy).not_to be_show
      end
    end
  end
end
