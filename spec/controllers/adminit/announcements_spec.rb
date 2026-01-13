require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::AnnouncementsController, type: :controller do
  include_context "user and permissions adminit"

  let(:announcement_permission) { create(:permission, resource: Adminit::AnnouncementPolicy.identifier, roles: [user.role, user_superadmin.role]) }

  describe "GET #index" do
    subject { get :index }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"
    end
  end

  describe "GET #show" do
    let(:announcement) { create(:announcement) }

    subject { get :show, params: {id: announcement.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"
    end
  end

  describe "GET #new" do
    subject { get :new }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:create?, Announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"
    end
  end

  describe "POST #create" do
    let(:valid_params) { {announcement: attributes_for(:announcement)} }
    let(:invalid_params) { {announcement: {title: nil, body: nil}} }

    subject { post :create, params: valid_params }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      it "creates a new announcement" do
        expect { subject }.to change(Announcement, :count).by(1)
      end

      it "sets the author to current_account" do
        subject
        expect(Announcement.last.author).to eq(user)
      end

      it "redirects to the announcement" do
        expect(subject).to redirect_to(adminit_announcement_path(Announcement.last))
      end

      context "with invalid params" do
        subject { post :create, params: invalid_params }

        it "does not create a new announcement" do
          expect { subject }.not_to change(Announcement, :count)
        end

        it "returns unprocessable entity" do
          expect(subject).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "PATCH #update" do
    let(:announcement) { create(:announcement, :draft) }
    let(:params) { {id: announcement.id, announcement: {title: "Updated Title"}} }

    subject { patch :update, params: params }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      context "when announcement is draft" do
        it "updates the announcement" do
          expect { subject }.to change { announcement.reload.title }.to("Updated Title")
        end

        it "redirects to the announcement" do
          expect(subject).to redirect_to(adminit_announcement_path(announcement))
        end
      end

      context "when announcement is scheduled" do
        let(:announcement) { create(:announcement, :scheduled) }

        it "allows updating title" do
          expect { subject }.to change { announcement.reload.title }.to("Updated Title")
        end

        context "when trying to change scheduled_at" do
          let(:params) { {id: announcement.id, announcement: {scheduled_at: 2.days.from_now}} }

          it "does not update scheduled_at" do
            original_time = announcement.scheduled_at
            subject
            expect(announcement.reload.scheduled_at).to be_within(1.second).of(original_time)
          end

          it "returns unprocessable entity" do
            expect(subject).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context "when announcement is published" do
        let(:announcement) { create(:announcement, :published) }

        it "does not update the announcement" do
          original_title = announcement.title
          subject
          expect(announcement.reload.title).to eq(original_title)
        end

        it "returns unprocessable entity" do
          expect(subject).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:announcement) { create(:announcement, :draft) }

    subject { delete :destroy, params: {id: announcement.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      context "when announcement is draft" do
        it "destroys the announcement" do
          expect { subject }.to change(Announcement, :count).by(-1)
        end

        it "redirects to index" do
          expect(subject).to redirect_to(adminit_announcements_path)
        end
      end

      context "when announcement is scheduled" do
        let!(:announcement) { create(:announcement, :scheduled) }

        it "does not destroy the announcement" do
          expect { subject }.not_to change(Announcement, :count)
        end

        it "shows error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end

      context "when announcement is published" do
        let!(:announcement) { create(:announcement, :published) }

        it "does not destroy the announcement" do
          expect { subject }.not_to change(Announcement, :count)
        end

        it "shows error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "POST #schedule" do
    let(:announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now) }

    subject { post :schedule, params: {id: announcement.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      context "when announcement is schedulable" do
        it "transitions to scheduled status" do
          expect { subject }.to change { announcement.reload.status }.from("draft").to("scheduled")
        end

        it "enqueues a PublishAnnouncementJob" do
          expect { subject }.to have_enqueued_job(PublishAnnouncementJob)
        end

        it "redirects to the announcement" do
          expect(subject).to redirect_to(adminit_announcement_path(announcement))
        end

        it "shows success message" do
          subject
          expect(flash[:notice]).to include("scheduled")
        end
      end

      context "when announcement has no scheduled_at" do
        let(:announcement) { create(:announcement, :draft, scheduled_at: nil) }

        it "does not change status" do
          subject
          expect(announcement.reload.status).to eq("draft")
        end

        it "shows error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end

      context "when announcement is already scheduled" do
        let(:announcement) { create(:announcement, :scheduled) }

        it "does not change status" do
          subject
          expect(announcement.reload.status).to eq("scheduled")
        end

        it "shows error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "POST #unschedule" do
    let(:announcement) { create(:announcement, :scheduled) }

    subject { post :unschedule, params: {id: announcement.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        announcement_permission
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, announcement).with(Adminit::AnnouncementPolicy).with_context(user: user)
      end

      context "when announcement is scheduled" do
        it "transitions to draft status" do
          expect { subject }.to change { announcement.reload.status }.from("scheduled").to("draft")
        end

        it "redirects to the announcement" do
          expect(subject).to redirect_to(adminit_announcement_path(announcement))
        end

        it "shows success message" do
          subject
          expect(flash[:notice]).to include("unscheduled")
        end
      end

      context "when announcement is draft" do
        let(:announcement) { create(:announcement, :draft) }

        it "does not change status" do
          subject
          expect(announcement.reload.status).to eq("draft")
        end

        it "shows error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end

      context "when announcement is published" do
        let(:announcement) { create(:announcement, :published) }

        it "does not change status" do
          subject
          expect(announcement.reload.status).to eq("published")
        end

        it "shows error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
