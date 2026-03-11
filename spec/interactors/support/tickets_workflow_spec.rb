require "rails_helper"

RSpec.describe "Ticket Workflow", type: :interactor do
  let(:user) { create(:account) }
  let(:admin) { create(:account, :with_role) }
  let(:ticket) { create(:ticket, created: user) }

  describe "Transitions and Notes" do
    it "handles the full reopen workflow" do
      # 1. Admin takes the ticket
      result = Adminit::Tickets::Take.call(ticket: ticket, account: admin)
      expect(result.success?).to be(true), result.error
      expect(ticket.reload.status).to eq("in_progress")
      expect(ticket.assigned).to eq(admin)
      expect(ticket.notes.first.body).to include("taken and assigned")

      # 2. Admin finishes the ticket
      result = Adminit::Tickets::Finish.call(ticket: ticket, account: admin)
      expect(result.success?).to be(true), result.error
      expect(ticket.reload.status).to eq("finished")
      expect(ticket.notes.first.body).to include("marked as finished")

      # 3. User requests reopen
      result = Support::Tickets::RequestReopen.call(ticket: ticket, account: user, body: "It is still broken")
      expect(result.success?).to be(true), result.error
      expect(ticket.reload.status).to eq("reopen_requested")
      expect(ticket.notes.first.body).to include("requested to reopen")
      expect(ticket.notes.first.body).to include("It is still broken")

      # 4. Admin accepts reopen
      result = Adminit::Tickets::AcceptReopen.call(ticket: ticket, account: admin)
      expect(result.success?).to be(true), result.error
      expect(ticket.reload.status).to eq("reopened")
      expect(ticket.notes.first.body).to include("accepted the reopen request")
    end

    it "handles reopen rejection" do
      ticket.update!(status: :finished)
      Support::Tickets::RequestReopen.call(ticket: ticket, account: user, body: "Reopen please")

      result = Adminit::Tickets::RejectReopen.call(ticket: ticket, account: admin, body: "Not valid reason")
      expect(result.success?).to be(true), result.error
      expect(ticket.reload.status).to eq("closed")
      expect(ticket.notes.first.body).to include("rejected the reopen request")
      expect(ticket.notes.first.body).to include("Not valid reason")
    end
  end

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
