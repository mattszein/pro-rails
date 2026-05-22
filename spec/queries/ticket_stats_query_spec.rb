require "rails_helper"

RSpec.describe TicketStatsQuery do
  describe ".call" do
    let(:account) { create(:account, :verified) }

    it "returns ticket stats" do
      create(:ticket, status: :open, created: account)
      create(:ticket, status: :finished, created: account, assigned: account)
      create(:ticket, status: :finished, created: account, assigned: account)

      stats = described_class.call

      expect(stats[:total]).to eq(3)
      expect(stats[:open]).to eq(1)
      expect(stats[:by_status]).to include("open" => 1, "finished" => 2)
    end
  end
end
