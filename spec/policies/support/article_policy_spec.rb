require "rails_helper"

RSpec.describe Support::ArticlePolicy, type: :policy do
  let(:account) { create(:account, :verified) }

  describe "#index?" do
    it "allows an authenticated user" do
      expect(described_class.new(:article, user: account)).to be_index
    end
  end

  describe "#show?" do
    it "allows a published article" do
      expect(described_class.new(build(:article, :published), user: account)).to be_show
    end

    it "denies a draft" do
      expect(described_class.new(build(:article), user: account)).not_to be_show
    end
  end
end
