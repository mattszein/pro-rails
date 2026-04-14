require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:avatar).optional }
    it { is_expected.to have_many(:avatars).dependent(:destroy) }
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
  end
end
