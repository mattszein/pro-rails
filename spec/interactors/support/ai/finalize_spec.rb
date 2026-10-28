require "rails_helper"

RSpec.describe Support::Ai::Finalize, type: :interactor do
  let(:ticket) { create(:ticket, :ai_analyzing) }
  let(:playbook) { create(:ai_playbook) }
  let(:reply) { {reply: "Try this.", article_ids: [], resolution_proposed: false, handoff_requested: false, handoff_reason: ""}.with_indifferent_access }

  def call_step(**ctx)
    described_class.call({ticket: ticket, playbook: playbook, triage: nil, reply: reply, trigger_message: nil}.merge(ctx))
  end

  it "posts the reply and waits for the user without a note" do
    call_step
    expect(ticket.reload).to be_ai_awaiting_user
    expect(ticket.conversation.messages.ai.last.content).to eq("Try this.")
    expect(ticket.notes).to be_empty
  end

  context "when the pass ends in a handoff" do
    let(:handoff) { reply.merge(handoff_requested: true, handoff_reason: "Needs a refund") }

    it "writes ONE ai note from the reason when Handle wrote none, without any model call" do
      expect(SupportAi::Responder).not_to receive(:new)
      result = call_step(reply: handoff)

      expect(ticket.reload).to be_ai_handoff_requested
      expect(ticket.notes.ai.pluck(:body)).to eq(["AI handoff: Needs a refund"])
      expect(result.note_written).to be(true)
      expect(ticket.conversation.messages.ai.last.content).to eq(I18n.t("support.ai.handoff_message"))
    end

    it "writes no second note when Handle already wrote one" do
      call_step(reply: handoff, note_written: true)
      expect(ticket.reload).to be_ai_handoff_requested
      expect(ticket.notes).to be_empty
    end

    it "uses the triage escalation reason" do
      call_step(reply: nil, triage: {escalate: true, escalate_reason: "legal threat"}.with_indifferent_access)
      expect(ticket.notes.ai.pluck(:body)).to eq(["AI handoff: legal threat"])
    end

    it "uses a generic reason when the model gave none" do
      call_step(reply: handoff.merge(handoff_reason: ""))
      expect(ticket.notes.ai.pluck(:body)).to eq(["AI handoff: assistant requested a human"])
    end

    it "hands off at the maximum AI turns" do
      playbook.update!(max_ai_turns: 1)
      call_step
      expect(ticket.notes.ai.pluck(:body)).to eq(["AI handoff: maximum AI turns reached"])
    end
  end

  it "discards when the AI no longer owns the ticket" do
    ticket.update!(ai_state: :stepped_back)
    result = call_step(reply: reply.merge(handoff_requested: true, handoff_reason: "x"))
    expect(result.discarded).to be(true)
    expect(ticket.notes).to be_empty
  end
end
