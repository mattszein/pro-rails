require "rails_helper"

RSpec.describe Avatars::Generate, type: :interactor do
  let(:profile) { create(:profile) }
  let(:avatar) { create(:avatar, :guided, profile: profile) }

  describe ".call" do
    context "when within rate limit" do
      before do
        allow_any_instance_of(AvatarAi::PromptAssembler).to receive(:assemble)
          .and_return("pixel art avatar, explorer energy, bold, neon colors")
      end

      it "succeeds" do
        result = described_class.call(avatar: avatar)
        expect(result).to be_success
      end

      it "assembles prompt and saves it" do
        described_class.call(avatar: avatar)
        expect(avatar.reload.assembled_prompt).to eq("pixel art avatar, explorer energy, bold, neon colors")
      end

      it "transitions avatar to generating" do
        described_class.call(avatar: avatar)
        expect(avatar.reload).to be_generating
      end

      it "enqueues the image generation job" do
        expect {
          described_class.call(avatar: avatar)
        }.to have_enqueued_job(GenerateAvatarImageJob).with(avatar.id)
      end
    end

    context "when rate limit exceeded" do
      before do
        allow(AvatarAiConfig).to receive(:max_generations_per_day).and_return(1)
        create(:avatar, :completed_generation, :with_image, profile: profile, created_at: Time.current)
      end

      it "fails with rate limited error" do
        result = described_class.call(avatar: avatar)
        expect(result).to be_failure
        expect(result.rate_limited).to be true
        expect(result.error).to include("limit")
      end

      it "does not transition avatar" do
        described_class.call(avatar: avatar)
        expect(avatar.reload).to be_draft
      end
    end

    context "when avatar is not in draft state" do
      let(:avatar) { create(:avatar, :generating) }

      it "fails with transition error" do
        allow_any_instance_of(AvatarAi::PromptAssembler).to receive(:assemble).and_return("prompt")
        result = described_class.call(avatar: avatar)
        expect(result).to be_failure
      end
    end
  end
end
