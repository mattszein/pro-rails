require "rails_helper"

RSpec.describe Adminit::ArticlePolicy, type: :policy do
  let(:admin_role) { create(:role, name: "admin") }
  let(:permission) { create(:permission, resource: :article, roles: [admin_role]) }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:article) { create(:article) }

  describe "#manage?" do
    context "when user has permission for ArticlePolicy" do
      before { permission }

      let(:policy) { described_class.new(article, user: admin_account) }

      it "allows access" do
        expect(policy).to be_manage
      end
    end

    context "when user has no role" do
      let(:regular_user) { create(:account, :verified) }
      let(:policy) { described_class.new(article, user: regular_user) }

      it "denies access" do
        expect(policy).not_to be_manage
      end
    end

    context "when user has role but no permission for ArticlePolicy" do
      let(:other_role) { create(:role, name: "other") }
      let(:other_account) { create(:account, :verified, role: other_role) }
      let(:policy) { described_class.new(article, user: other_account) }

      it "denies access" do
        expect(policy).not_to be_manage
      end
    end

    context "when user is superadmin" do
      let(:superadmin_role) { create(:role, :superadmin) }
      let(:superadmin_account) { create(:account, :verified, role: superadmin_role) }
      let(:policy) { described_class.new(article, user: superadmin_account) }

      before do
        create(:permission, resource: :article, roles: [superadmin_role])
      end

      it "allows access" do
        expect(policy).to be_manage
      end
    end
  end
end
