require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

RSpec.describe Settings::AvatarsController, type: :request do
  let(:account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:avatar) { create(:avatar, :with_image, profile: account.profile) }
  let(:other_avatar) { create(:avatar, :with_image, profile: other_account.profile) }

  describe "GET /settings/avatars" do
    context "when not logged in" do
      it "redirects to login" do
        get settings_avatars_path
        expect(response).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in" do
      before { login_user(account) }

      it "returns success" do
        get settings_avatars_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /settings/avatars/new" do
    context "when not logged in" do
      it "redirects to login" do
        get new_settings_avatar_path
        expect(response).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in" do
      before { login_user(account) }

      it "returns success" do
        get new_settings_avatar_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /settings/avatars (manual upload)" do
    before { login_user(account) }

    let(:image_file) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/avatar.png"),
        "image/png"
      )
    end

    it "uploads avatar and redirects to profile" do
      post settings_avatars_path, params: {avatar: {image: image_file}}
      expect(response).to redirect_to(edit_settings_profile_path)
    end

    it "creates a manual avatar" do
      expect {
        post settings_avatars_path, params: {avatar: {image: image_file}}
      }.to change(Avatar, :count).by(1)
    end
  end

  describe "POST /settings/avatars (wizard start)" do
    before { login_user(account) }

    it "creates a generated draft avatar and redirects to show" do
      expect {
        post settings_avatars_path, params: {avatar: {method: "guided"}}
      }.to change(Avatar, :count).by(1)

      new_avatar = Avatar.last
      expect(response).to redirect_to(settings_avatar_path(new_avatar))
      expect(new_avatar.kind).to eq("generated")
      expect(new_avatar.status).to eq("draft")
    end
  end

  describe "GET /settings/avatars/:id" do
    before { login_user(account) }

    it "returns success for own avatar" do
      get settings_avatar_path(avatar)
      expect(response).to have_http_status(:ok)
    end

    it "redirects when accessing other's avatar" do
      get settings_avatar_path(other_avatar)
      expect(response).to be_redirect
    end
  end

  describe "POST /settings/avatars/:id/select" do
    before { login_user(account) }

    it "sets avatar as active and redirects" do
      post select_settings_avatar_path(avatar)
      expect(account.profile.reload.avatar).to eq(avatar)
      expect(response).to redirect_to(edit_settings_profile_path)
    end
  end

  describe "PATCH /settings/avatars/:id/toggle_visibility" do
    before { login_user(account) }

    it "toggles avatar visibility" do
      initial = avatar.visible
      patch toggle_visibility_settings_avatar_path(avatar)
      expect(avatar.reload.visible).to eq(!initial)
    end
  end
end
