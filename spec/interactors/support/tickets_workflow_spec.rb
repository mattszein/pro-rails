require "rails_helper"

RSpec.describe "Ticket message policy by status", type: :interactor do
  let(:user) { create(:account) }
  let(:ticket) { create(:ticket, created: user) }

  describe "Message Policy" do
    let(:policy) { Support::MessagePolicy.new(message, user: user) }
    let(:message) { build(:message, conversation: ticket.conversation) }

    it "allows messaging when in_progress" do
      ticket.update!(status: :in_progress)
      expect(policy.create?).to be true
    end

    it "allows messaging when reopened" do
      ticket.update!(status: :reopened)
      expect(policy.create?).to be true
    end

    it "denies messaging when open" do
      ticket.update!(status: :open)
      expect(policy.create?).to be false
    end

    it "denies messaging when finished" do
      ticket.update!(status: :finished)
      expect(policy.create?).to be false
    end

    it "denies messaging when closed" do
      ticket.update!(status: :closed)
      expect(policy.create?).to be false
    end
  end
end
