require "rails_helper"

RSpec.describe Avatars::Upload, type: :interactor do
  let(:profile) { create(:profile) }
  let(:image_file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/avatar.png"),
      "image/png"
    )
  end

  describe ".call" do
    context "with valid image" do
      it "succeeds" do
        result = described_class.call(profile: profile, image_file: image_file)
        expect(result).to be_success
      end

      it "creates a manual avatar" do
        expect {
          described_class.call(profile: profile, image_file: image_file)
        }.to change(Avatar, :count).by(1)

        avatar = Avatar.last
        expect(avatar.kind).to eq("manual")
        expect(avatar.status).to eq("completed")
        expect(avatar.profile).to eq(profile)
      end

      it "attaches the image to the avatar" do
        described_class.call(profile: profile, image_file: image_file)
        expect(Avatar.last.image).to be_attached
      end

      it "sets the avatar as active on the profile" do
        result = described_class.call(profile: profile, image_file: image_file)
        expect(profile.reload.avatar).to eq(result.avatar)
      end

      it "returns the created avatar in context" do
        result = described_class.call(profile: profile, image_file: image_file)
        expect(result.avatar).to be_a(Avatar)
      end
    end

    context "with invalid content type" do
      let(:bad_file) do
        file = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/files/avatar.png"),
          "application/pdf"
        )
        file
      end

      it "fails with error" do
        result = described_class.call(profile: profile, image_file: bad_file)
        expect(result).to be_failure
        expect(result.error).to include("JPEG")
      end

      it "does not create an avatar" do
        expect {
          described_class.call(profile: profile, image_file: bad_file)
        }.not_to change(Avatar, :count)
      end
    end
  end
end
