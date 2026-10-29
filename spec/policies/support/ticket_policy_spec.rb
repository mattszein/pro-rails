require "rails_helper"

RSpec.describe Support::TicketPolicy, type: :policy do
  let(:creator_account) { create(:account, :verified) }
  let(:other_account) { create(:account, :verified) }
  let(:ticket) { create(:ticket, created: creator_account) }

  describe "#index?" do
    it "allows when user is present" do
      policy = described_class.new(:ticket, user: creator_account)
      expect(policy).to be_index
    end
  end

  describe "#new?" do
    it "allows when user is present" do
      policy = described_class.new(:ticket, user: creator_account)
      expect(policy).to be_new
    end
  end

  describe "#create?" do
    it "allows when user is present" do
      policy = described_class.new(:ticket, user: creator_account)
      expect(policy).to be_create
    end
  end

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

  describe "#resolve_with_ai?" do
    it "allows the creator of an open ticket awaiting the user" do
      ticket = create(:ticket, :ai_awaiting_user, created: creator_account)
      expect(described_class.new(ticket, user: creator_account)).to be_resolve_with_ai
    end

    it "denies other users" do
      ticket = create(:ticket, :ai_awaiting_user, created: creator_account)
      expect(described_class.new(ticket, user: other_account)).not_to be_resolve_with_ai
    end

    %i[ai_analyzing ai_handoff_requested ai_stepped_back ai_resolved].each do |trait|
      it "denies the creator when #{trait}" do
        ticket = create(:ticket, trait, created: creator_account)
        expect(described_class.new(ticket, user: creator_account)).not_to be_resolve_with_ai
      end
    end

    it "denies a ticket that is not open" do
      ticket = create(:ticket, :in_progress, ai_state: :awaiting_user, created: creator_account)
      expect(described_class.new(ticket, user: creator_account)).not_to be_resolve_with_ai
    end
  end

  describe "#request_human?" do
    it "allows the creator while the assistant waits for them" do
      ticket = create(:ticket, :ai_awaiting_user, created: creator_account)
      expect(described_class.new(ticket, user: creator_account)).to be_request_human
    end

    %i[ai_analyzing ai_handoff_requested ai_stepped_back ai_resolved].each do |trait|
      it "denies the creator when #{trait}" do
        ticket = create(:ticket, trait, created: creator_account)
        expect(described_class.new(ticket, user: creator_account)).not_to be_request_human
      end
    end

    it "denies the creator when the AI is off" do
      expect(described_class.new(create(:ticket, created: creator_account), user: creator_account)).not_to be_request_human
    end

    it "denies other users" do
      ticket = create(:ticket, :ai_awaiting_user, created: creator_account)
      expect(described_class.new(ticket, user: other_account)).not_to be_request_human
    end
  end
end
