require "rails_helper"

RSpec.describe Avatars::Evolve, type: :interactor do
  let(:profile) { create(:profile) }
  let(:source_avatar) { create(:avatar, :completed_generation, :with_image, profile: profile) }

  describe ".call" do
    context "when within rate limit and avatar is evolvable" do
      it "succeeds" do
        result = described_class.call(avatar: source_avatar)
        expect(result).to be_success
      end

      it "creates a new draft avatar" do
        source_avatar # force evaluation before counting
        expect {
          described_class.call(avatar: source_avatar)
        }.to change(Avatar, :count).by(1)

        new_avatar = Avatar.last
        expect(new_avatar.kind).to eq("generated")
        expect(new_avatar.status).to eq("draft")
        expect(new_avatar.profile).to eq(profile)
      end

      it "clones the DNA from source avatar" do
        described_class.call(avatar: source_avatar)
        new_avatar = Avatar.last
        expect(new_avatar.dna).to eq(source_avatar.dna)
        expect(new_avatar.method).to eq(source_avatar.method)
        expect(new_avatar.dna_version).to eq(source_avatar.dna_version)
      end

      it "returns the new avatar in context" do
        result = described_class.call(avatar: source_avatar)
        expect(result.avatar).to be_a(Avatar)
        expect(result.avatar).not_to eq(source_avatar)
      end
    end

    context "when rate limit exceeded" do
      before do
        allow(AvatarAiConfig).to receive(:max_generations_per_day).and_return(1)
        create(:avatar, :completed_generation, :with_image, profile: profile, created_at: Time.current)
      end

      it "fails with rate limited error" do
        result = described_class.call(avatar: source_avatar)
        expect(result).to be_failure
        expect(result.rate_limited).to be true
      end
    end

    context "when avatar is not evolvable" do
      let(:not_evolvable) { create(:avatar, :generated, profile: profile) }

      it "fails" do
        result = described_class.call(avatar: not_evolvable)
        expect(result).to be_failure
      end
    end
  end
end
