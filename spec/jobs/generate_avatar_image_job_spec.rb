require "rails_helper"

RSpec.describe GenerateAvatarImageJob, type: :job do
  let(:profile) { create(:profile) }
  let(:avatar) { create(:avatar, :generating, profile: profile) }

  describe "#perform" do
    context "when avatar exists and is generating" do
      let(:image_io) { File.open(Rails.root.join("spec/fixtures/files/avatar.png")) }
      let(:mock_result) { {io: image_io, content_type: "image/png"} }

      before do
        allow_any_instance_of(AvatarAi::ImageGenerator).to receive(:generate)
          .and_return(mock_result)
      end

      it "generates and attaches the image" do
        described_class.perform_now(avatar.id)
        expect(avatar.reload.image).to be_attached
      end

      it "transitions avatar to completed" do
        described_class.perform_now(avatar.id)
        expect(avatar.reload).to be_completed
      end
    end

    context "when avatar does not exist" do
      it "does nothing without error" do
        expect { described_class.perform_now(0) }.not_to raise_error
      end
    end

    context "when avatar is not generating (already processed)" do
      let(:completed_avatar) { create(:avatar, :completed_generation, :with_image, profile: profile) }

      it "does nothing (idempotency guard)" do
        expect_any_instance_of(AvatarAi::ImageGenerator).not_to receive(:generate)
        described_class.perform_now(completed_avatar.id)
        expect(completed_avatar.reload).to be_completed
      end
    end

    context "when image generation fails" do
      before do
        allow_any_instance_of(AvatarAi::ImageGenerator).to receive(:generate)
          .and_raise(AvatarAi::ImageGenerator::GenerationError, "API timeout")
      end

      it "transitions avatar to failed" do
        described_class.perform_now(avatar.id)
        expect(avatar.reload).to be_failed
      end

      it "does not re-raise the error" do
        expect { described_class.perform_now(avatar.id) }.not_to raise_error
      end
    end

    context "when avatar is manual kind" do
      let(:manual_avatar) do
        a = create(:avatar, :generating, profile: profile)
        a.update_column(:kind, 0) # manual
        a
      end

      it "does nothing (guard on generated? check)" do
        expect_any_instance_of(AvatarAi::ImageGenerator).not_to receive(:generate)
        described_class.perform_now(manual_avatar.id)
      end
    end
  end
end
