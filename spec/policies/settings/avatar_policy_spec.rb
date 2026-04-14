require "rails_helper"

RSpec.describe Settings::AvatarPolicy, type: :policy do
  let(:account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:avatar) { create(:avatar, :with_image, profile: account.profile) }
  let(:other_avatar) { create(:avatar, :with_image, profile: other_account.profile) }

  describe "#index?" do
    it "allows any authenticated user" do
      policy = described_class.new(Avatar, user: account)
      expect(policy).to be_index
    end
  end

  describe "#create?" do
    it "allows any authenticated user" do
      policy = described_class.new(Avatar, user: account)
      expect(policy).to be_create
    end
  end

  describe "#show?" do
    it "allows owner" do
      policy = described_class.new(avatar, user: account)
      expect(policy).to be_show
    end

    it "denies non-owner" do
      policy = described_class.new(other_avatar, user: account)
      expect(policy).not_to be_show
    end
  end

  describe "#update?" do
    it "allows owner" do
      policy = described_class.new(avatar, user: account)
      expect(policy).to be_update
    end

    it "denies non-owner" do
      policy = described_class.new(other_avatar, user: account)
      expect(policy).not_to be_update
    end
  end

  describe "#generate?" do
    it "allows owner" do
      policy = described_class.new(avatar, user: account)
      expect(policy).to be_generate
    end

    it "denies non-owner" do
      policy = described_class.new(other_avatar, user: account)
      expect(policy).not_to be_generate
    end
  end

  describe "#select?" do
    it "allows owner" do
      policy = described_class.new(avatar, user: account)
      expect(policy).to be_select
    end

    it "denies non-owner" do
      policy = described_class.new(other_avatar, user: account)
      expect(policy).not_to be_select
    end
  end

  describe "#evolve?" do
    it "allows owner" do
      policy = described_class.new(avatar, user: account)
      expect(policy).to be_evolve
    end

    it "denies non-owner" do
      policy = described_class.new(other_avatar, user: account)
      expect(policy).not_to be_evolve
    end
  end

  describe "#toggle_visibility?" do
    it "allows owner" do
      policy = described_class.new(avatar, user: account)
      expect(policy).to be_toggle_visibility
    end

    it "denies non-owner" do
      policy = described_class.new(other_avatar, user: account)
      expect(policy).not_to be_toggle_visibility
    end
  end
end
