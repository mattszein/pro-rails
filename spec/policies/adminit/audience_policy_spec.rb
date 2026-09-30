require "rails_helper"

RSpec.describe Adminit::AudiencePolicy, type: :policy do
  let(:admin_role) { create(:role, name: "audience_admin") }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:audience) { create(:audience) }

  describe "#manage?" do
    context "when user has permission for AudiencePolicy" do
      before { create(:permission, resource: :audience, roles: [admin_role]) }

      it "allows access" do
        policy = described_class.new(audience, user: admin_account)
        expect(policy).to be_manage
      end
    end

    context "when user has no role" do
      it "denies access" do
        regular_user = create(:account, :verified)
        policy = described_class.new(audience, user: regular_user)
        expect(policy).not_to be_manage
      end
    end

    context "when user has role but no permission for AudiencePolicy" do
      it "denies access" do
        other_role = create(:role, name: "other")
        other_account = create(:account, :verified, role: other_role)
        policy = described_class.new(audience, user: other_account)
        expect(policy).not_to be_manage
      end
    end
  end

  # None of these are overridden methods — they resolve through
  # ActionPolicy's alias/default_rule machinery, which only activates via
  # `allowed_to?` (calling `.index?`/`.create?` directly would hit
  # ActionPolicy::Policy::Defaults' own hardcoded methods, always false,
  # bypassing the alias to manage? entirely; `.archive?`/`.unarchive?` are
  # not even defined as literal methods).
  describe "#index? / #create? / #update? / #archive? / #unarchive? (resolved via allowed_to?)" do
    it "all follow the manage? permission" do
      create(:permission, resource: :audience, roles: [admin_role])
      policy = described_class.new(audience, user: admin_account)

      expect(policy.allowed_to?(:index?)).to be true
      expect(policy.allowed_to?(:create?)).to be true
      expect(policy.allowed_to?(:update?)).to be true
      expect(policy.allowed_to?(:archive?)).to be true
      expect(policy.allowed_to?(:unarchive?)).to be true
    end

    it "all deny without permission" do
      regular_user = create(:account, :verified)
      policy = described_class.new(audience, user: regular_user)

      expect(policy.allowed_to?(:index?)).to be false
      expect(policy.allowed_to?(:create?)).to be false
      expect(policy.allowed_to?(:update?)).to be false
      expect(policy.allowed_to?(:archive?)).to be false
      expect(policy.allowed_to?(:unarchive?)).to be false
    end
  end

  # No `destroy?` override here — what proves audiences are never destroyed
  # in Adminit is that no admin controller ever asks: AudiencesController
  # defines no destroy action, and the routes expose no destroy path (see
  # spec/controllers/adminit/audiences_spec.rb).
end
