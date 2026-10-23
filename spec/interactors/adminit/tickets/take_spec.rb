require "rails_helper"

RSpec.describe Adminit::Tickets::Take, type: :interactor do
  let(:admin) { create(:account, :verified, :with_role) }
  let(:other_admin) { create(:account, :verified, :with_role) }
  let(:ticket) { create(:ticket) }

  it "assigns the ticket, moves it to in_progress and writes the note" do
    result = described_class.call(ticket: ticket, account: admin)
    expect(result).to be_success
    expect(ticket.reload).to be_in_progress
    expect(ticket.assigned).to eq(admin)
    expect(ticket.notes.system.first.body).to eq("Ticket taken and assigned.")
  end

  it "fails when already assigned, even if the caller's record is stale" do
    stale = Support::Ticket.find(ticket.id)
    described_class.call(ticket: ticket, account: other_admin)

    result = described_class.call(ticket: stale, account: admin)
    expect(result).to be_failure
    expect(result.error).to eq(I18n.t("adminit.tickets.already_assigned"))
    expect(ticket.reload.assigned).to eq(other_admin)
    expect(ticket.notes.count).to eq(1)
  end

  it "locks the row inside a transaction" do
    expect(ticket).to receive(:lock!).and_call_original
    described_class.call(ticket: ticket, account: admin)
  end

  context "when the AI was engaged" do
    %i[ai_awaiting_user ai_handoff_requested ai_analyzing].each do |trait|
      it "steps the AI back with a note (#{trait})" do
        ticket = create(:ticket, trait)
        described_class.call(ticket: ticket, account: admin)
        expect(ticket.reload).to be_ai_stepped_back
        expect(ticket.notes.system.pluck(:body)).to include("Ticket taken and assigned.", "AI stepped back.")
      end
    end

    it "removes the typing indicator when it was analyzing" do
      ticket = create(:ticket, :ai_analyzing)
      expect(Support::Ai::Typing).to receive(:hide).with(ticket)
      described_class.call(ticket: ticket, account: admin)
    end

    it "does not touch typing otherwise" do
      ticket = create(:ticket, :ai_awaiting_user)
      expect(Support::Ai::Typing).not_to receive(:hide)
      described_class.call(ticket: ticket, account: admin)
    end
  end

  it "leaves the AI state alone and writes no AI note when it was not engaged" do
    ticket = create(:ticket, ai_state: :resolved)
    described_class.call(ticket: ticket, account: admin)
    expect(ticket.reload).to be_ai_resolved
    expect(ticket.notes.pluck(:body)).to eq(["Ticket taken and assigned."])
  end
end
