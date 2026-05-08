
require "rails_helper"

RSpec.describe Avatars::GenerateImageJob, type: :job do
  let(:profile) { create(:profile) }
  let(:avatar) { create(:avatar, :generating, profile: profile) }

  describe "#perform" do
    context "when avatar exists and is generating" do
      let(:success_context) { double("context", failure?: false) }

      before do
        allow(Avatars::GenerateImage).to receive(:call)
          .with(avatar: avatar)
          .and_return(success_context)
      end

      it "calls the GenerateImage interactor" do
        described_class.perform_now(avatar.id)
        expect(Avatars::GenerateImage).to have_received(:call).with(avatar: avatar)
      end
    end

    context "when avatar does not exist" do
      it "does nothing without error" do
        expect { described_class.perform_now(0) }.not_to raise_error
      end
    end

    context "when avatar is not generating (already processed)" do
      let(:completed_avatar) { create(:avatar, :completed_generation, :with_image, profile: profile) }

      it "does not call the interactor (idempotency guard)" do
        expect(Avatars::GenerateImage).not_to receive(:call)
        described_class.perform_now(completed_avatar.id)
      end
    end

    context "when avatar is manual kind" do
      let(:manual_avatar) do
        a = create(:avatar, :generating, profile: profile)
        a.update_column(:kind, 0)
        a
      end

      it "does not call the interactor (generated? guard)" do
        expect(Avatars::GenerateImage).not_to receive(:call)
        described_class.perform_now(manual_avatar.id)
      end
    end

    context "when the interactor fails" do
      let(:failure_context) { double("context", failure?: true, error: "API timeout") }

      before do
        allow(Avatars::GenerateImage).to receive(:call)
          .with(avatar: avatar)
          .and_return(failure_context)
      end

      it "logs a warning and does not re-raise" do
        expect(Rails.logger).to receive(:warn).with(/GenerateImageJob failed/)
        expect { described_class.perform_now(avatar.id) }.not_to raise_error
      end
    end
  end
end
