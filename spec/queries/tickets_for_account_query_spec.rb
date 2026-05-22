require "rails_helper"

RSpec.describe TicketsForAccountQuery do
  let(:account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }

  describe ".call" do
    it "returns tickets assigned to the account" do
      ticket = create(:ticket, assigned: account, created: other_account)
      create(:ticket, assigned: other_account, created: other_account)

      result = described_class.call(account: account)
      expect(result).to eq([ticket])
    end

    it "limits the number of results" do
      5.times { create(:ticket, assigned: account, created: other_account) }

      result = described_class.call(account: account, limit: 3)
      expect(result.count).to eq(3)
    end
  end
end
