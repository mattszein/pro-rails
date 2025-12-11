require "rails_helper"

RSpec.describe Support::TicketPolicy, type: :policy do
  let(:creator_account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:ticket) { create(:ticket, created: creator_account) }

  describe "#show?" do
    context "when user is the creator" do
      let(:policy) { described_class.new(ticket, user: creator_account) }

      it "allows user to view the ticket" do
        expect(policy).to be_show
      end
    end

    context "when user is not the creator" do
      let(:policy) { described_class.new(ticket, user: other_account) }

      it "denies user from viewing the ticket" do
        expect(policy).not_to be_show
      end
    end
  end

  describe "#update?" do
    context "when user is the creator" do
      let(:policy) { described_class.new(ticket, user: creator_account) }

      it "allows user to update the ticket" do
        expect(policy).to be_update
      end
    end

    context "when user is not the creator" do
      let(:policy) { described_class.new(ticket, user: other_account) }

      it "denies user from updating the ticket" do
        expect(policy).not_to be_update
      end
    end
  end

  describe "#destroy?" do
    context "when user is the creator" do
      let(:policy) { described_class.new(ticket, user: creator_account) }

      it "allows user to destroy the ticket" do
        expect(policy).to be_destroy
      end
    end

    context "when user is not the creator" do
      let(:policy) { described_class.new(ticket, user: other_account) }

      it "denies user from destroying the ticket" do
        expect(policy).not_to be_destroy
      end
    end
  end

  describe "#attach_files?" do
    context "when user is the creator" do
      let(:policy) { described_class.new(ticket, user: creator_account) }

      it "allows user to attach files to the ticket" do
        expect(policy).to be_attach_files
      end
    end

    context "when user is not the creator" do
      let(:policy) { described_class.new(ticket, user: other_account) }

      it "denies user from attaching files to the ticket" do
        expect(policy).not_to be_attach_files
      end
    end
  end
end
