require "rails_helper"

RSpec.describe "AI flows", type: :interactor do
  let(:user) { create(:account, :verified) }
  let(:ticket) { create(:ticket, :ai_analyzing, created: user, priority: 4) }
  let!(:playbook) { create(:ai_playbook, :default, capabilities: %w[auto_set_priority investigate_note]) }

  describe Support::Ai::Flows::ProcessTicket do
    def call_organizer
      described_class.call(ticket: ticket, trigger: "ticket_created")
    end

    it "runs triage, applies it, handles (note + reply) and waits for the user (assist)" do
      responder = stub_responder(triage: ai_result(triage_output(priority: 2)), handle: ai_result(handle_output(findings: "note body")))

      expect(call_organizer).to be_success

      ticket.reload
      expect(ticket).to be_ai_awaiting_user
      expect(ticket.priority).to eq(2)
      expect(ticket.ai_runs.where(step: :handle).pluck(:playbook_id)).to eq([playbook.id])
      expect(ticket.conversation.messages.ai.count).to eq(1)
      expect(ticket.notes.system.pluck(:body)).to include("AI set priority 2 (was 4): Cannot log in")
      expect(ticket.notes.ai.pluck(:body)).to eq(["note body\nHelp center: no article answered this."])
      expect(ticket.conversation.messages.ai.last.content).to eq("Try resetting your password.")
      expect(ticket.ai_runs.order(:id).pluck(:step, :status)).to eq([%w[triage succeeded], %w[handle succeeded]])
      expect(responder).to have_received(:handle).with(hash_including(triage: hash_including(priority: 2), reply: true))
    end

    it "carries on when triage fails" do
      stub_responder(triage: SupportAi::Error.new("x"), handle: ai_result(handle_output))
      expect(call_organizer).to be_success
      expect(ticket.reload).to be_ai_awaiting_user
      expect(ticket.ai_runs.failed.pluck(:step)).to eq(%w[triage])
    end

    it "raises when the handle step fails, leaving the ticket analyzing for the retry" do
      stub_responder(triage: ai_result(triage_output), handle: SupportAi::Error.new("boom"))
      expect { call_organizer }.to raise_error(SupportAi::Error)
      expect(ticket.reload).to be_ai_analyzing
      expect(ticket.ai_runs.handle.failed).to exist
      expect(ticket.notes.ai).to be_empty
    end

    it "turns the AI off when no playbook matches" do
      playbook.update!(enabled: false)
      stub_responder(triage: ai_result(triage_output))
      expect(call_organizer).to be_failure
      expect(ticket.reload).to be_ai_off
      expect(ticket.conversation.messages).to be_empty
    end

    it "hands off without talking to the user for a triage_only playbook" do
      playbook.update!(mode: :triage_only)
      responder = stub_responder(triage: ai_result(triage_output), handle: ai_result(handle_output(reply: nil)))
      call_organizer
      expect(responder).to have_received(:handle).with(hash_including(reply: false))
      expect(ticket.reload).to be_ai_handoff_requested
      expect(ticket.conversation.messages).to be_empty
      expect(ticket.notes.ai.pluck(:body)).to include("Request: reset password.\nContext: none\nNext step: send the reset link.\nHelp center: no article answered this.")
      expect(ticket.notes.ai.count).to eq(1)
    end

    it "escalates: handoff plus the generic message" do
      responder = stub_responder(triage: ai_result(triage_output(escalate: true, escalate_reason: "legal threat")), handle: ai_result(handle_output(reply: nil)))
      call_organizer
      expect(ticket.reload).to be_ai_handoff_requested
      expect(responder).to have_received(:handle).with(hash_including(reply: false))
      expect(ticket.conversation.messages.ai.last.content).to eq(I18n.t("support.ai.handoff_message"))
    end

    it "hands off with the fixed message and one note when the handle step reports a KB gap" do
      stub_responder(
        triage: ai_result(triage_output),
        handle: ai_result(handle_output(reply: "No encontre una guia.", kb_gap: true, kb_queries: ["csv"], handoff_requested: true, handoff_reason: "No help-center article matched (KB gap)"))
      )
      call_organizer
      ticket.reload
      expect(ticket).to be_ai_handoff_requested
      expect(ticket.conversation.messages.ai.last.content).to eq(I18n.t("support.ai.handoff_message"))
      expect(ticket.notes.ai.pluck(:body).grep(/Help center/).size).to eq(1)
      expect(ticket.notes.ai.pluck(:body).join).not_to include("KB gap")
      expect(ticket.ai_runs.find_by(step: :handle).output).to include("kb_gap" => true)
    end

    it "organizes flat steps in order" do
      expect(described_class.organized).to eq([Support::Ai::Triage, Support::Ai::SelectPlaybook, Support::Ai::ApplyTriage, Support::Ai::Handle, Support::Ai::Finalize])
    end
  end

  describe Support::Ai::Flows::ProcessReply do
    let(:trigger_message) { create(:message, conversation: ticket.conversation, account: user) }

    it "responds with the recorded playbook and finalizes" do
      create(:ai_run, ticket: ticket, step: :triage, output: triage_output(sentiment: "negative"))
      create(:ai_run, ticket: ticket, step: :handle, output: handle_output(findings: "Found it"))
      responder = stub_responder(respond: ai_result(respond_output))
      result = described_class.call(ticket: ticket, trigger: "user_message", trigger_message: trigger_message)

      expect(result).to be_success
      expect(responder).to have_received(:respond).with(trigger_message: trigger_message)
      expect(ticket.reload).to be_ai_awaiting_user
      expect(ticket.ai_runs.pluck(:step, :run_trigger)).to eq([%w[triage ticket_created], %w[handle ticket_created], %w[respond user_message]])
    end

    it "writes ONE ai handoff note from the model's reason, with no extra model call" do
      responder = stub_responder(respond: ai_result(respond_output(handoff_requested: true, handoff_reason: "Needs a refund")))
      described_class.call(ticket: ticket, trigger: "user_message", trigger_message: trigger_message)

      expect(ticket.reload).to be_ai_handoff_requested
      expect(ticket.notes.ai.pluck(:body)).to eq(["AI handoff: Needs a refund"])
      expect(ticket.conversation.messages.ai.last.content).to eq(I18n.t("support.ai.handoff_message"))
      expect(responder).to have_received(:respond).once
    end

    it "organizes flat steps in order" do
      expect(described_class.organized).to eq([Support::Ai::SelectPlaybook, Support::Ai::Respond, Support::Ai::Finalize])
    end

    it "raises on a respond failure" do
      stub_responder(respond: SupportAi::Error.new("boom"))
      expect { described_class.call(ticket: ticket, trigger: "user_message", trigger_message: trigger_message) }.to raise_error(SupportAi::Error)
    end
  end
end
