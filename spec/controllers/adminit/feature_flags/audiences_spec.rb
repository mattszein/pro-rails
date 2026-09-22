require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::FeatureFlags::AudiencesController, type: :controller do
  include_context "user and permissions adminit"

  describe "POST #create" do
    let(:flag) { create(:feature_flag) }
    let(:audience) { create(:audience) }

    subject { post :create, params: {feature_flag_id: flag.id, audience_id: audience.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
      end

      it "is authorized against the parent flag" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond with redirect"

      it "attaches the audience and shows a success flash" do
        subject
        expect(flag.reload.audiences).to include(audience)
        expect(flash[:notice]).to be_present
      end

      # S19 — an archived audience is not offered when attaching, and the
      # controller rejects one submitted directly, not only omits it from
      # the view. The app's existing RecordNotFoundHandler catches the
      # RecordNotFound this raises, same as any other bad id.
      it "rejects an archived audience_id, even submitted directly" do
        archived = create(:audience, :archived)

        post :create, params: {feature_flag_id: flag.id, audience_id: archived.id}

        expect(flag.reload.audiences).not_to include(archived)
        expect(response).to have_http_status(:found)
      end

      it "rejects an audience_id already attached to this flag" do
        create(:feature_flag_audience, feature_flag: flag, audience: audience)

        expect {
          post :create, params: {feature_flag_id: flag.id, audience_id: audience.id}
        }.not_to change(FeatureFlagAudience, :count)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:flag) { create(:feature_flag) }
    let(:audience) { create(:audience) }

    subject { delete :destroy, params: {feature_flag_id: flag.id, id: audience.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
        create(:feature_flag_audience, feature_flag: flag, audience: audience)
      end

      it "is authorized against the parent flag" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond with redirect"

      it "detaches the audience and shows a success flash" do
        subject
        expect(flag.reload.audiences).not_to include(audience)
        expect(flash[:notice]).to be_present
      end
    end
  end
end
