require "rails_helper"

RSpec.describe Support::AiProcessJob, type: :job do
  let(:user) { create(:account, :verified) }
  let(:ticket) { create(:ticket, :ai_analyzing, created: user) }
  let(:conversation) { ticket.conversation }

  before do
    allow(Support::Ai::Flows::ProcessTicket).to receive(:call).and_return(double(failure?: false))
    allow(Support::Ai::Flows::ProcessReply).to receive(:call).and_return(double(failure?: false))
  end

  it "uses the support_ai queue" do
    expect(described_class.new.queue_name).to eq("support_ai")
  end

  describe "ticket_created" do
    it "runs ProcessTicket" do
      described_class.perform_now(ticket.id, "ticket_created")
      expect(Support::Ai::Flows::ProcessTicket).to have_received(:call).with(ticket: ticket, trigger: "ticket_created")
    end

    it "does nothing when the ticket is gone" do
      expect { described_class.perform_now(0, "ticket_created") }.not_to raise_error
      expect(Support::Ai::Flows::ProcessTicket).not_to have_received(:call)
    end

    %i[ai_awaiting_user ai_handoff_requested ai_stepped_back].each do |trait|
      it "does nothing when the ticket is #{trait}" do
        other = create(:ticket, trait)
        described_class.perform_now(other.id, "ticket_created")
        expect(Support::Ai::Flows::ProcessTicket).not_to have_received(:call)
      end
    end

    it "does nothing when an AI message already exists (idempotent re-run)" do
      create(:message, :ai, conversation: conversation)
      described_class.perform_now(ticket.id, "ticket_created")
      expect(Support::Ai::Flows::ProcessTicket).not_to have_received(:call)
    end

    it "logs when the organizer halts" do
      allow(Support::Ai::Flows::ProcessTicket).to receive(:call).and_return(double(failure?: true, error: "No AI playbook matched"))
      ticket
      allow(Rails.logger).to receive(:info).and_call_original
      expect(Rails.logger).to receive(:info).with(/halted.*No AI playbook matched/)
      described_class.perform_now(ticket.id, "ticket_created")
    end
  end

  describe "user_message" do
    let!(:message) { create(:message, conversation: conversation, account: user) }

    it "runs ProcessReply with the trigger message" do
      described_class.perform_now(ticket.id, "user_message", message.id)
      expect(Support::Ai::Flows::ProcessReply).to have_received(:call).with(ticket: ticket, trigger: "user_message", trigger_message: message)
    end

    it "does nothing when the message is gone" do
      described_class.perform_now(ticket.id, "user_message", 0)
      expect(Support::Ai::Flows::ProcessReply).not_to have_received(:call)
    end

    it "debounces: a newer human message gets its own job" do
      create(:message, conversation: conversation, account: user, content: "second")
      described_class.perform_now(ticket.id, "user_message", message.id)
      expect(Support::Ai::Flows::ProcessReply).not_to have_received(:call)
    end

    it "does nothing when an AI message newer than the trigger exists" do
      create(:message, :ai, conversation: conversation)
      described_class.perform_now(ticket.id, "user_message", message.id)
      expect(Support::Ai::Flows::ProcessReply).not_to have_received(:call)
    end

    it "ignores AI messages older than the trigger" do
      older = create(:ticket, :ai_analyzing, created: user)
      create(:message, :ai, conversation: older.conversation)
      newer = create(:message, conversation: older.conversation, account: user)
      described_class.perform_now(older.id, "user_message", newer.id)
      expect(Support::Ai::Flows::ProcessReply).to have_received(:call)
    end

    it "does nothing when the ticket is no longer analyzing" do
      ticket.update!(ai_state: :stepped_back)
      described_class.perform_now(ticket.id, "user_message", message.id)
      expect(Support::Ai::Flows::ProcessReply).not_to have_received(:call)
    end
  end

  it "rejects unknown triggers" do
    expect { described_class.perform_now(ticket.id, "bogus") }.to raise_error(ArgumentError)
  end

  describe "retries" do
    it "retries Responder errors" do
      allow(Support::Ai::Flows::ProcessTicket).to receive(:call).and_raise(SupportAi::Error, "boom")
      expect { described_class.perform_now(ticket.id, "ticket_created") }.to have_enqueued_job(described_class).with(ticket.id, "ticket_created")
    end

    it "hands the ticket to a human through Fallback when attempts are exhausted" do
      allow(Support::Ai::Flows::ProcessTicket).to receive(:call).and_raise(SupportAi::Error, "boom")

      job = described_class.new(ticket.id, "ticket_created")
      3.times { job.perform_now } # the third attempt exhausts the retries

      expect(ticket.reload).to be_ai_handoff_requested
      expect(ticket.ai_runs.fallback).to exist
      expect(ticket.notes.system.pluck(:body)).to include("AI failed after retries; handed off")
    end
  end
end
