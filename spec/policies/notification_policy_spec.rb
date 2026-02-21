require "rails_helper"

RSpec.describe NotificationPolicy, type: :policy do
  let(:account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:notification) { create(:noticed_notification, recipient: account) }

  describe "#index?" do
    it "allows when user is present" do
      policy = described_class.new(:notification, user: account)
      expect(policy).to be_index
    end
  end

  describe "#user?" do
    it "allows when user is present" do
      policy = described_class.new(:notification, user: account)
      expect(policy).to be_user
    end
  end

  describe "#mark_all_read?" do
    it "allows when user is present" do
      policy = described_class.new(:notification, user: account)
      expect(policy).to be_mark_all_read
    end
  end

  describe "#mark_as_read?" do
    context "when user owns the notification" do
      let(:policy) { described_class.new(notification, user: account) }

      it "allows marking as read" do
        expect(policy).to be_mark_as_read
      end
    end

    context "when user does not own the notification" do
      let(:policy) { described_class.new(notification, user: other_account) }

      it "denies marking as read" do
        expect(policy).not_to be_mark_as_read
      end
    end
  end
end
