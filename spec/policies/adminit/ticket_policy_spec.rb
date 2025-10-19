require "rails_helper"

RSpec.describe Adminit::TicketPolicy, type: :policy do
  let(:admin_role) { create(:role, name: "admin") }
  let(:permission) { create(:permission, resource: Adminit::TicketPolicy.identifier, roles: [admin_role]) }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:creator_account) { create(:account, :verified) }
  let(:policy) { described_class.new(ticket, user: admin_account) }

  before do
    permission # Ensure permission exists
  end

  describe "#take?" do
    context "with an open ticket" do
      let(:ticket) { create(:ticket, status: :open, created: creator_account) }

      it "allows admin to take the ticket" do
        expect(policy).to be_take
      end
    end

    context "with a non-open ticket" do
      let(:ticket) { create(:ticket, :in_progress, created: creator_account) }

      it "denies admin from taking the ticket" do
        expect(policy).not_to be_take
      end
    end

    context "when user has no role" do
      let(:regular_user) { create(:account, :verified) }
      let(:ticket) { create(:ticket, status: :open, created: creator_account) }
      let(:policy) { described_class.new(ticket, user: regular_user) }

      it "denies user from taking the ticket" do
        expect(policy).not_to be_take
      end
    end
  end

  describe "#update?" do
    context "when admin is assigned to the ticket" do
      let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: admin_account) }

      it "allows admin to update the ticket" do
        expect(policy).to be_update
      end
    end

    context "when admin is not assigned to the ticket" do
      let(:other_admin) { create(:account, :verified, role: admin_role) }
      let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }

      it "denies admin from updating the ticket" do
        expect(policy).not_to be_update
      end
    end

    context "when superadmin" do
      let(:superadmin_role) { create(:role, :superadmin) }
      let(:superadmin_account) { create(:account, :verified, role: superadmin_role) }
      let(:other_admin) { create(:account, :verified, role: admin_role) }
      let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: other_admin) }
      let(:policy) { described_class.new(ticket, user: superadmin_account) }

      before do
        # Add superadmin role to existing permission
        permission.roles << superadmin_role unless permission.roles.include?(superadmin_role)
      end

      it "allows superadmin to update any ticket" do
        expect(policy).to be_update
      end
    end

    context "when user has no role" do
      let(:regular_user) { create(:account, :verified) }
      let(:ticket) { create(:ticket, :in_progress, created: creator_account, assigned: admin_account) }
      let(:policy) { described_class.new(ticket, user: regular_user) }

      it "denies user from updating the ticket" do
        expect(policy).not_to be_update
      end
    end
  end

  describe "#manage?" do
    context "when admin has permission" do
      let(:ticket) { create(:ticket, created: creator_account) }

      it "allows admin to manage tickets" do
        expect(policy).to be_manage
      end
    end

    context "when user has no role" do
      let(:regular_user) { create(:account, :verified) }
      let(:ticket) { create(:ticket, created: creator_account) }
      let(:policy) { described_class.new(ticket, user: regular_user) }

      it "denies user from managing tickets" do
        expect(policy).not_to be_manage
      end
    end
  end
end
