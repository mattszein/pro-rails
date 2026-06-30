require "rails_helper"

RSpec.describe AccountStatsQuery do
  describe ".call" do
    it "returns account stats" do
      create_list(:account, 2, :verified)
      create(:account)
      verified_account = Account.verified.first
      AccountRememberKey.create!(id: verified_account.id, key: "secret", deadline: 1.week.from_now)

      stats = described_class.call

      expect(stats[:total]).to eq(3)
      expect(stats[:verified]).to eq(2)
      expect(stats[:active_sessions]).to eq(1)
      expect(stats[:by_month]).to be_a(Hash)
      expect(stats[:by_month].values).to include(3)
    end
  end
end
