require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_one_attached(:avatar) }
  end

  describe "validations" do
    it { is_expected.to validate_length_of(:bio).is_at_most(500) }

    describe "username format" do
      it { is_expected.to allow_value("valid_username").for(:username) }
      it { is_expected.to allow_value("valid123").for(:username) }
      it { is_expected.to allow_value("").for(:username) }
      it { is_expected.not_to allow_value("invalid username").for(:username) }
      it { is_expected.not_to allow_value("invalid!").for(:username) }
    end

    describe "username uniqueness" do
      let!(:profile) { create(:profile, username: "taken") }

      it "does not allow duplicate usernames" do
        new_profile = build(:profile, account: create(:account), username: "taken")
        expect(new_profile).not_to be_valid
      end

      it "allows blank usernames" do
        new_profile = build(:profile, account: create(:account), username: "")
        expect(new_profile).to be_valid
      end
    end

    describe "avatar validation" do
      let(:profile) { create(:account).profile }

      it "rejects invalid content types" do
        profile.avatar.attach(
          io: StringIO.new("fake pdf"),
          filename: "document.pdf",
          content_type: "application/pdf"
        )
        expect(profile).not_to be_valid
        expect(profile.errors[:avatar]).to be_present
      end

      it "accepts valid image content types" do
        profile.avatar.attach(
          io: Rails.root.join("spec/fixtures/files/avatar.png").open,
          filename: "avatar.png",
          content_type: "image/png"
        )
        expect(profile).to be_valid
      end
    end
  end
end
