require "rails_helper"

RSpec.describe TicketStatsQuery do
  describe ".call" do
    let(:account) { create(:account, :verified) }

    it "returns ticket stats" do
      create(:ticket, status: :open, created: account)
      create(:ticket, status: :in_progress, created: account, assigned: account)
      create(:ticket, status: :finished, created: account, assigned: account)
      create(:ticket, status: :closed, created: account, assigned: account)

      stats = described_class.call

      expect(stats[:total]).to eq(4)
      expect(stats[:open]).to eq(1)
      expect(stats[:in_progress]).to eq(1)
      expect(stats[:resolved]).to eq(2)
      expect(stats[:by_status]).to include("open" => 1, "in_progress" => 1, "finished" => 1, "closed" => 1)
    end
  end
end
