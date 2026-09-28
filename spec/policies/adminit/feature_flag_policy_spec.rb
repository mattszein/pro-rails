require "rails_helper"

RSpec.describe Adminit::FeatureFlagPolicy, type: :policy do
  let(:admin_role) { create(:role, name: "flag_admin") }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:flag) { create(:feature_flag) }

  describe "#manage?" do
    context "when user has permission for FeatureFlagPolicy" do
      before { create(:permission, resource: :feature_flag, roles: [admin_role]) }

      it "allows access" do
        policy = described_class.new(flag, user: admin_account)
        expect(policy).to be_manage
      end
    end

    context "when user has no role" do
      it "denies access" do
        regular_user = create(:account, :verified)
        policy = described_class.new(flag, user: regular_user)
        expect(policy).not_to be_manage
      end
    end

    context "when user has role but no permission for FeatureFlagPolicy" do
      it "denies access" do
        other_role = create(:role, name: "other")
        other_account = create(:account, :verified, role: other_role)
        policy = described_class.new(flag, user: other_account)
        expect(policy).not_to be_manage
      end
    end
  end

  # None of these are overridden methods — they resolve through ActionPolicy's
  # alias/default_rule machinery, which only activates via `allowed_to?`
  # (calling `.index?` directly would hit ActionPolicy::Policy::Defaults' own
  # hardcoded `index?` => false, bypassing the alias entirely).
  describe "#index? / #show? / #update? / #create? / #destroy? (resolved via allowed_to?)" do
    it "all follow the manage? permission" do
      create(:permission, resource: :feature_flag, roles: [admin_role])
      policy = described_class.new(flag, user: admin_account)

      expect(policy.allowed_to?(:index?)).to be true
      expect(policy.allowed_to?(:show?)).to be true
      expect(policy.allowed_to?(:update?)).to be true
      expect(policy.allowed_to?(:create?)).to be true
      expect(policy.allowed_to?(:destroy?)).to be true
    end

    it "all deny without permission" do
      regular_user = create(:account, :verified)
      policy = described_class.new(flag, user: regular_user)

      expect(policy.allowed_to?(:index?)).to be false
      expect(policy.allowed_to?(:show?)).to be false
      expect(policy.allowed_to?(:update?)).to be false
      expect(policy.allowed_to?(:create?)).to be false
      expect(policy.allowed_to?(:destroy?)).to be false
    end
  end

  # No route or controller action ever asks create?/destroy? — flags are
  # declared in code, never created or destroyed in Adminit. The routes
  # expose no such path either (see spec/controllers/adminit/feature_flags_spec.rb).
end
