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

  it "writes the findings note with a normal reply" do
    call_step(note_body: "Expired session.")
    expect(ticket.reload).to be_ai_awaiting_user
    expect(ticket.notes.ai.pluck(:body)).to eq(["Expired session."])
    expect(ticket.conversation.messages.ai.count).to eq(1)
  end

  it "rolls back note, message and transition together on failure" do
    allow(ticket).to receive(:await_user_reply!).and_raise(ActiveRecord::RecordInvalid)
    expect { call_step(note_body: "Expired session.") }.to raise_error(ActiveRecord::RecordInvalid)
    expect(ticket.notes.reload).to be_empty
    expect(ticket.conversation.messages.ai).to be_empty
    expect(ticket.reload).to be_ai_analyzing
  end

  context "when the pass ends in a handoff" do
    let(:handoff) { reply.merge(handoff_requested: true, handoff_reason: "Needs a refund") }

    it "writes ONE ai note from the reason when Handle wrote none, without any model call" do
      expect(SupportAi::Responder).not_to receive(:new)
      call_step(reply: handoff)

      expect(ticket.reload).to be_ai_handoff_requested
      expect(ticket.notes.ai.pluck(:body)).to eq(["AI handoff: Needs a refund"])
      expect(ticket.conversation.messages.ai.last.content).to eq(I18n.t("support.ai.handoff_message"))
    end

    it "writes ONE note: the findings body ending with the handoff line" do
      call_step(reply: handoff, note_body: "Expired session.\nHelp center: no article answered this.")
      expect(ticket.reload).to be_ai_handoff_requested
      expect(ticket.notes.ai.pluck(:body)).to eq(["Expired session.\nHelp center: no article answered this.\nAI handoff: Needs a refund"])
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

  describe "discarding" do
    let(:run) { create(:ai_run, ticket: ticket, playbook: playbook, step: :handle, status: :succeeded, output: {"findings" => "Expired session."}) }
    let(:not_sent) { "Reply not sent: the ticket changed while the assistant was working." }

    it "discards when the AI no longer owns the ticket" do
      ticket.update!(ai_state: :stepped_back)
      result = call_step(reply: reply.merge(handoff_requested: true, handoff_reason: "x"))
      expect(result.discarded).to be(true)
      expect(ticket.notes).to be_empty
    end

    it "keeps the findings in a note ending with the not-sent line, without handoff line, message or transition" do
      ticket.update!(ai_state: :stepped_back)
      result = call_step(reply: reply.merge(handoff_requested: true, handoff_reason: "x"), note_body: "Expired session.", handle_run: run)

      expect(result.discarded).to be(true)
      expect(ticket.notes.ai.pluck(:body)).to eq(["Expired session.\n#{not_sent}"])
      expect(ticket.conversation.messages.ai).to be_empty
      expect(ticket.reload).to be_ai_stepped_back
      expect(run.reload).to be_discarded
      expect(run.output).to include("findings" => "Expired session.")
    end
  end
end
