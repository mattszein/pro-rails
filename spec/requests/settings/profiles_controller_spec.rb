require "rails_helper"

RSpec.describe "Settings::Profiles", type: :request do
  let(:account) { create(:account, :verified) }
  let(:profile) { account.profile }

  describe "GET /settings/profile/edit" do
    context "when unauthenticated" do
      it "redirects to login" do
        get edit_settings_profile_path
        expect(response).to redirect_to(rodauth.login_path)
      end
    end

    context "when authenticated" do
      before { login_user(account) }

      it "renders the edit page" do
        get edit_settings_profile_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /settings/profile" do
    before { login_user(account) }

    let(:avatar) { fixture_file_upload("spec/fixtures/files/avatar.png", "image/png") }

    context "with valid params" do
      let(:params) do
        {
          profile: {
            bio: "Updated bio.",
            username: "updated_username",
            avatar: avatar
          }
        }
      end

      it "updates the profile and redirects" do
        patch settings_profile_path, params: params
        expect(response).to redirect_to(edit_settings_profile_path)
        expect(flash[:notice]).to eq(I18n.t("settings.profiles.update.success"))
        expect(profile.reload.bio).to eq("Updated bio.")
        expect(profile.reload.username).to eq("updated_username")
      end
    end

    context "with invalid params" do
      let(:params) do
        {
          profile: {
            username: "invalid username!"
          }
        }
      end

      it "returns unprocessable content" do
        patch settings_profile_path, params: params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("can only contain letters, numbers, and underscores")
      end
    end
  end
end
