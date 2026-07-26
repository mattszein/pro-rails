require "rails_helper"

RSpec.describe Avatars::Select, type: :interactor do
  let(:profile) { create(:profile) }
  let(:avatar) { create(:avatar, :with_image, profile: profile) }

  describe ".call" do
    context "when avatar is selectable" do
      it "succeeds" do
        result = described_class.call(avatar: avatar, profile: profile)
        expect(result).to be_success
      end

      it "sets avatar as active on profile" do
        described_class.call(avatar: avatar, profile: profile)
        expect(profile.reload.avatar).to eq(avatar)
      end

      it "returns the avatar in context" do
        result = described_class.call(avatar: avatar, profile: profile)
        expect(result.avatar).to eq(avatar)
      end
    end

    context "when avatar is not selectable (draft)" do
      let(:avatar) { create(:avatar, :generated, profile: profile) }

      it "fails" do
        result = described_class.call(avatar: avatar, profile: profile)
        expect(result).to be_failure
      end

      it "does not update profile" do
        described_class.call(avatar: avatar, profile: profile)
        expect(profile.reload.avatar).not_to eq(avatar)
      end
    end
  end
end
