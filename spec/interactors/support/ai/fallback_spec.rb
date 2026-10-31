require "rails_helper"

RSpec.describe Support::Ai::Fallback, type: :interactor do
  let(:ticket) { create(:ticket, :ai_analyzing) }

  it "hands off with a generic AI message, a system note and a failed fallback run" do
    described_class.call(ticket: ticket, error: "provider down")

    expect(ticket.reload).to be_ai_handoff_requested
    expect(ticket.conversation.messages.ai.last.content).to eq(I18n.t("support.ai.handoff_message"))
    expect(I18n.t("support.ai.handoff_message")).to eq("We're looking into this. I've passed your request to a teammate on our support team, and they'll follow up here.")
    expect(ticket.notes.system.first.body).to eq("AI failed after retries; handed off")
    expect(ticket.ai_runs.last).to have_attributes(run_trigger: "fallback", status: "failed", error: "provider down")
  end

  it "also works while awaiting the user" do
    ticket.update!(ai_state: :awaiting_user)
    described_class.call(ticket: ticket)
    expect(ticket.reload).to be_ai_handoff_requested
  end

  it "is idempotent" do
    described_class.call(ticket: ticket)
    counts = -> { [Support::Message.count, Support::Note.count, Support::AiRun.count] }
    expect { described_class.call(ticket: ticket) }.not_to change(&counts)
  end

  it "does nothing once a human took over" do
    ticket.update!(ai_state: :stepped_back)
    described_class.call(ticket: ticket)
    expect(ticket.reload).to be_ai_stepped_back
  end
end
