require "rails_helper"

RSpec.describe "Adminit::Announcements", type: :request do
  let(:admin_role) { create(:role, name: "admin") }
  let(:permission) { create(:permission, resource: Adminit::AnnouncementPolicy.identifier, roles: [admin_role]) }
  let(:admin_account) { create(:account, :verified, role: admin_role) }
  let(:announcement) { create(:announcement, author: admin_account) }

  before do
    permission # Ensure permission exists
    login_user(admin_account)
  end

  describe "GET /adminit/announcements" do
    it "returns http success" do
      get adminit_announcements_path
      expect(response).to have_http_status(:success)
    end

    it "displays announcements" do
      announcement
      get adminit_announcements_path
      expect(response.body).to include(announcement.title)
    end
  end

  describe "GET /adminit/announcements/:id" do
    it "returns http success" do
      get adminit_announcement_path(announcement)
      expect(response).to have_http_status(:success)
    end

    it "displays announcement details" do
      get adminit_announcement_path(announcement)
      expect(response.body).to include(announcement.title)
      expect(response.body).to include(announcement.body)
    end
  end

  describe "GET /adminit/announcements/new" do
    it "returns http success" do
      get new_adminit_announcement_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /adminit/announcements" do
    let(:valid_attributes) { attributes_for(:announcement, status: :draft) }
    let(:invalid_attributes) { attributes_for(:announcement, title: nil) }

    context "with valid parameters" do
      it "creates a new announcement" do
        expect {
          post adminit_announcements_path, params: {announcement: valid_attributes}
        }.to change(Announcement, :count).by(1)
      end

      it "sets the author to current_account" do
        post adminit_announcements_path, params: {announcement: valid_attributes}
        expect(Announcement.last.author).to eq(admin_account)
      end

      it "redirects to the created announcement" do
        post adminit_announcements_path, params: {announcement: valid_attributes}
        expect(response).to redirect_to(adminit_announcement_path(Announcement.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new announcement" do
        expect {
          post adminit_announcements_path, params: {announcement: invalid_attributes}
        }.not_to change(Announcement, :count)
      end

      it "returns unprocessable entity status" do
        post adminit_announcements_path, params: {announcement: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /adminit/announcements/:id" do
    let(:new_attributes) { {title: "Updated Title"} }

    context "with valid parameters" do
      it "updates the announcement" do
        patch adminit_announcement_path(announcement), params: {announcement: new_attributes}
        announcement.reload
        expect(announcement.title).to eq("Updated Title")
      end

      it "redirects to the announcement" do
        patch adminit_announcement_path(announcement), params: {announcement: new_attributes}
        expect(response).to redirect_to(adminit_announcement_path(announcement))
      end
    end
  end

  describe "POST /adminit/announcements/:id/publish" do
    context "when announcement has valid scheduled_at" do
      let(:draft_announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now, author: admin_account) }

      it "changes status to scheduled" do
        post publish_adminit_announcement_path(draft_announcement)
        draft_announcement.reload
        expect(draft_announcement.status).to eq("scheduled")
      end

      it "redirects to the announcement" do
        post publish_adminit_announcement_path(draft_announcement)
        expect(response).to redirect_to(adminit_announcement_path(draft_announcement))
      end
    end

    context "when announcement has no scheduled_at" do
      let(:draft_announcement) { create(:announcement, :draft, author: admin_account) }

      it "does not change status" do
        post publish_adminit_announcement_path(draft_announcement)
        draft_announcement.reload
        expect(draft_announcement.status).to eq("draft")
      end

      it "shows error message" do
        post publish_adminit_announcement_path(draft_announcement)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "DELETE /adminit/announcements/:id" do
    context "when announcement is draft" do
      let(:draft_announcement) { create(:announcement, :draft, author: admin_account) }

      it "destroys the announcement" do
        draft_announcement # Create announcement
        expect {
          delete adminit_announcement_path(draft_announcement)
        }.to change(Announcement, :count).by(-1)
      end

      it "redirects to announcements index" do
        delete adminit_announcement_path(draft_announcement)
        expect(response).to redirect_to(adminit_announcements_path)
      end
    end

    context "when announcement is scheduled" do
      let(:scheduled_announcement) { create(:announcement, :scheduled, author: admin_account) }

      it "does not destroy the announcement" do
        scheduled_announcement # Create announcement
        expect {
          delete adminit_announcement_path(scheduled_announcement)
        }.not_to change(Announcement, :count)
      end

      it "redirects with unauthorized message" do
        delete adminit_announcement_path(scheduled_announcement)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    context "when announcement is published" do
      let(:published_announcement) { create(:announcement, :published, author: admin_account) }

      it "does not destroy the announcement" do
        published_announcement # Create announcement
        expect {
          delete adminit_announcement_path(published_announcement)
        }.not_to change(Announcement, :count)
      end

      it "redirects with unauthorized message" do
        delete adminit_announcement_path(published_announcement)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /adminit/announcements/:id (update restrictions)" do
    context "when announcement is draft" do
      let(:draft_announcement) { create(:announcement, :draft, author: admin_account) }

      it "allows updating" do
        patch adminit_announcement_path(draft_announcement), params: {announcement: {title: "Updated"}}
        draft_announcement.reload
        expect(draft_announcement.title).to eq("Updated")
      end
    end

    context "when announcement is scheduled" do
      let(:scheduled_announcement) { create(:announcement, :scheduled, author: admin_account) }

      it "allows updating title and body" do
        patch adminit_announcement_path(scheduled_announcement), params: {announcement: {title: "Updated Title"}}
        scheduled_announcement.reload
        expect(scheduled_announcement.title).to eq("Updated Title")
      end

      it "does not allow changing scheduled_at" do
        original_time = scheduled_announcement.scheduled_at
        new_time = 2.days.from_now
        patch adminit_announcement_path(scheduled_announcement), params: {announcement: {scheduled_at: new_time}}
        scheduled_announcement.reload
        expect(scheduled_announcement.scheduled_at).to be_within(1.second).of(original_time)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when announcement is published" do
      let(:published_announcement) { create(:announcement, :published, author: admin_account) }

      it "redirects with unauthorized message" do
        patch adminit_announcement_path(published_announcement), params: {announcement: {title: "Updated"}}
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end

      it "does not update the announcement" do
        original_title = published_announcement.title
        patch adminit_announcement_path(published_announcement), params: {announcement: {title: "Updated"}}
        published_announcement.reload
        expect(published_announcement.title).to eq(original_title)
      end
    end
  end

  describe "POST /adminit/announcements/:id/draft" do
    context "when announcement is scheduled" do
      let(:scheduled_announcement) { create(:announcement, :scheduled, author: admin_account) }

      it "transitions to draft" do
        post draft_adminit_announcement_path(scheduled_announcement)
        scheduled_announcement.reload
        expect(scheduled_announcement.status).to eq("draft")
      end

      it "redirects to the announcement" do
        post draft_adminit_announcement_path(scheduled_announcement)
        expect(response).to redirect_to(adminit_announcement_path(scheduled_announcement))
      end
    end

    context "when announcement is published" do
      let(:published_announcement) { create(:announcement, :published, author: admin_account) }

      it "redirects with unauthorized message" do
        post draft_adminit_announcement_path(published_announcement)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end

      it "does not change status" do
        post draft_adminit_announcement_path(published_announcement)
        published_announcement.reload
        expect(published_announcement.status).to eq("published")
      end
    end
  end

  describe "POST /adminit/announcements/:id/publish (authorization)" do
    context "when announcement is already scheduled" do
      let(:scheduled_announcement) { create(:announcement, :scheduled, author: admin_account) }

      it "redirects with unauthorized message" do
        post publish_adminit_announcement_path(scheduled_announcement)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    context "when announcement is published" do
      let(:published_announcement) { create(:announcement, :published, author: admin_account) }

      it "redirects with unauthorized message" do
        post publish_adminit_announcement_path(published_announcement)
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end
  end


end
