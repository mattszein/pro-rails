require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::FeatureFlags::AccountsController, type: :controller do
  include_context "user and permissions adminit"

  describe "POST #create" do
    let(:flag) { create(:feature_flag) }
    let(:account) { create(:account) }

    subject { post :create, params: {feature_flag_id: flag.id, account_id: account.id, access: "allowed"} }

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

      it "adds the account entry and shows a success flash" do
        subject
        entry = flag.reload.account_entries.find_by(account: account)
        expect(entry).to be_allowed
        expect(flash[:notice]).to be_present
      end

      # S9 second line — changing an allow into a block updates the row in
      # place rather than requiring the earlier one removed first.
      it "updates an existing entry's access in place" do
        entry = create(:feature_flag_account, :allowed, feature_flag: flag, account: account)

        post :create, params: {feature_flag_id: flag.id, account_id: account.id, access: "blocked"}

        reloaded = flag.account_entries.find_by(account: account)
        expect(reloaded.id).to eq(entry.id)
        expect(reloaded).to be_blocked
      end
    end
  end

  describe "DELETE #destroy" do
    let(:flag) { create(:feature_flag) }
    let(:account) { create(:account) }

    subject { delete :destroy, params: {feature_flag_id: flag.id, id: account.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        feature_flag_permission
        create(:feature_flag_account, :allowed, feature_flag: flag, account: account)
      end

      it "is authorized against the parent flag" do
        expect { subject }.to be_authorized_to(:manage?, flag).with(Adminit::FeatureFlagPolicy).with_context(user: user)
      end

      it_behaves_like "respond with redirect"

      it "removes the account entry and shows a success flash" do
        subject
        expect(flag.reload.account_entries.exists?(account: account)).to be false
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "GET #search" do
    subject { get :search, params: {feature_flag_id: create(:feature_flag).id, q: "user"} }

    include_context "adminit_auth"

    context "when logged with permission" do
      let(:flag) { create(:feature_flag) }

      before do
        login_user(user)
        feature_flag_permission
      end

      it "excludes closed accounts (S14 — a closed account can never be granted)" do
        matching = create(:account, email: "user_open@example.com")
        closed = create(:account, :closed, email: "user_closed@example.com")

        get :search, params: {feature_flag_id: flag.id, q: "user_"}

        values = response.parsed_body.pluck("value")
        expect(values).to include(matching.id.to_s)
        expect(values).not_to include(closed.id.to_s)
      end

      it "short-circuits a too-short query to an empty list" do
        get :search, params: {feature_flag_id: flag.id, q: "a"}
        expect(response.parsed_body).to eq([])
      end
    end
  end
end
