require "rails_helper"

RSpec.describe Adminit::AnnouncementPolicy, type: :policy do
  let(:admin_role) { create(:role, name: "admin") }
  let(:permission) { create(:permission, resource: Adminit::AnnouncementPolicy.identifier, roles: [admin_role]) }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:author_account) { create(:account, :verified, role: admin_role) }
  let(:announcement) { create(:announcement, author: author_account) }
  let(:policy) { described_class.new(announcement, user: admin_account) }

  before do
    permission # Ensure permission exists
  end

  describe "#manage?" do
    context "when admin has permission" do
      it "allows admin to manage announcements" do
        expect(policy).to be_manage
      end
    end

    context "when user has no role" do
      let(:regular_user) { create(:account, :verified) }
      let(:policy) { described_class.new(announcement, user: regular_user) }

      it "denies user from managing announcements" do
        expect(policy).not_to be_manage
      end
    end

    context "when user has role but no permission" do
      let(:other_role) { create(:role, name: "other") }
      let(:other_account) { create(:account, :verified, role: other_role) }
      let(:policy) { described_class.new(announcement, user: other_account) }

      it "denies user from managing announcements" do
        expect(policy).not_to be_manage
      end
    end
  end

  describe "superadmin" do
    let(:superadmin_role) { create(:role, :superadmin) }
    let(:superadmin_account) { create(:account, :verified, role: superadmin_role) }
    let(:policy) { described_class.new(announcement, user: superadmin_account) }

    before do
      permission.roles << superadmin_role unless permission.roles.include?(superadmin_role)
    end

    it "allows superadmin to manage announcements" do
      expect(policy).to be_manage
    end
  end

  describe "#destroy?" do
    context "when user has permission" do
      it "allows destroying draft announcements" do
        draft_announcement = create(:announcement, :draft, author: author_account)
        policy = described_class.new(draft_announcement, user: admin_account)
        expect(policy).to be_destroy
      end

      it "denies destroying scheduled announcements" do
        scheduled_announcement = create(:announcement, :scheduled, author: author_account)
        policy = described_class.new(scheduled_announcement, user: admin_account)
        expect(policy).not_to be_destroy
      end

      it "denies destroying published announcements" do
        published_announcement = create(:announcement, :published, author: author_account)
        policy = described_class.new(published_announcement, user: admin_account)
        expect(policy).not_to be_destroy
      end
    end

    context "when user has no permission" do
      let(:regular_user) { create(:account, :verified) }

      it "denies destroying any announcements" do
        draft_announcement = create(:announcement, :draft, author: author_account)
        policy = described_class.new(draft_announcement, user: regular_user)
        expect(policy).not_to be_destroy
      end
    end
  end

  describe "#update?" do
    context "when user has permission" do
      it "allows updating draft announcements" do
        draft_announcement = create(:announcement, :draft, author: author_account)
        policy = described_class.new(draft_announcement, user: admin_account)
        expect(policy).to be_update
      end

      it "allows updating scheduled announcements" do
        scheduled_announcement = create(:announcement, :scheduled, author: author_account)
        policy = described_class.new(scheduled_announcement, user: admin_account)
        expect(policy).to be_update
      end

      it "denies updating published announcements" do
        published_announcement = create(:announcement, :published, author: author_account)
        policy = described_class.new(published_announcement, user: admin_account)
        expect(policy).not_to be_update
      end
    end

    context "when user has no permission" do
      let(:regular_user) { create(:account, :verified) }

      it "denies updating any announcements" do
        draft_announcement = create(:announcement, :draft, author: author_account)
        policy = described_class.new(draft_announcement, user: regular_user)
        expect(policy).not_to be_update
      end
    end
  end

  describe "#edit?" do
    it "mirrors update? authorization" do
      draft_announcement = create(:announcement, :draft, author: author_account)
      policy = described_class.new(draft_announcement, user: admin_account)
      expect(policy.edit?).to eq(policy.update?)
    end
  end

  describe "#publish?" do
    context "when user has permission" do
      it "allows publishing draft announcements" do
        draft_announcement = create(:announcement, :draft, author: author_account)
        policy = described_class.new(draft_announcement, user: admin_account)
        expect(policy).to be_publish
      end

      it "denies publishing already scheduled announcements" do
        scheduled_announcement = create(:announcement, :scheduled, author: author_account)
        policy = described_class.new(scheduled_announcement, user: admin_account)
        expect(policy).not_to be_publish
      end

      it "denies publishing already published announcements" do
        published_announcement = create(:announcement, :published, author: author_account)
        policy = described_class.new(published_announcement, user: admin_account)
        expect(policy).not_to be_publish
      end
    end

    context "when user has no permission" do
      let(:regular_user) { create(:account, :verified) }

      it "denies publishing any announcements" do
        draft_announcement = create(:announcement, :draft, author: author_account)
        policy = described_class.new(draft_announcement, user: regular_user)
        expect(policy).not_to be_publish
      end
    end
  end

  describe "#draft?" do
    context "when user has permission" do
      it "allows transitioning draft to draft" do
        draft_announcement = create(:announcement, :draft, author: author_account)
        policy = described_class.new(draft_announcement, user: admin_account)
        expect(policy).to be_draft
      end

      it "allows transitioning scheduled to draft" do
        scheduled_announcement = create(:announcement, :scheduled, author: author_account)
        policy = described_class.new(scheduled_announcement, user: admin_account)
        expect(policy).to be_draft
      end

      it "denies transitioning published to draft" do
        published_announcement = create(:announcement, :published, author: author_account)
        policy = described_class.new(published_announcement, user: admin_account)
        expect(policy).not_to be_draft
      end
    end

    context "when user has no permission" do
      let(:regular_user) { create(:account, :verified) }

      it "denies transitioning any announcements to draft" do
        scheduled_announcement = create(:announcement, :scheduled, author: author_account)
        policy = described_class.new(scheduled_announcement, user: regular_user)
        expect(policy).not_to be_draft
      end
    end
  end
end
