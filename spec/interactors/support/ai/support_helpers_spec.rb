require "rails_helper"

RSpec.describe Support::Ai::RecordRun do
  let(:ticket) { create(:ticket) }
  let(:playbook) { create(:ai_playbook) }

  it "records a successful hash result" do
    result = ai_result(triage_output, tool_calls: [{name: "x", arguments: {}}])
    run = described_class.call(ticket: ticket, playbook: playbook, trigger: "ticket_created", step: :triage, result: result)

    expect(run).to be_persisted
    expect(run).to have_attributes(status: "succeeded", step: "triage", run_trigger: "ticket_created", model: "stub-model",
      input_tokens: 10, output_tokens: 5, latency_ms: 120, playbook: playbook, error: nil)
    expect(run.output["priority"]).to eq(3)
    expect(run.tool_calls.first["name"]).to eq("x")
  end

  it "wraps string output as text" do
    run = described_class.call(ticket: ticket, trigger: :ticket_created, step: :investigate, result: ai_result("findings"))
    expect(run.output).to eq({"text" => "findings"})
  end

  it "records an error as failed" do
    run = described_class.call(ticket: ticket, trigger: :user_message, step: :respond, error: SupportAi::Error.new("boom"))
    expect(run).to have_attributes(status: "failed", error: "boom", output: {})
  end

  it "stores the transcript from a result" do
    transcript = [{role: "user", content: "hi", tool_calls: [], tool_call_id: nil}]
    run = described_class.call(ticket: ticket, trigger: :ticket_created, step: :respond, result: ai_result(respond_output, transcript: transcript))
    expect(run.transcript).to eq(transcript.as_json)
  end

  it "stores transcript and tool_calls from an error" do
    error = SupportAi::Error.new("boom", transcript: [{role: "user", content: "hi"}], tool_calls: [{name: "account_facts", arguments: {}}])
    run = described_class.call(ticket: ticket, trigger: :user_message, step: :respond, error: error)

    expect(run.transcript).to eq([{"role" => "user", "content" => "hi"}])
    expect(run.tool_calls).to eq([{"name" => "account_facts", "arguments" => {}}])
  end

  it "accepts an explicit status" do
    run = described_class.call(ticket: ticket, trigger: :user_message, step: :respond, result: ai_result(respond_output), status: :discarded)
    expect(run.status).to eq("discarded")
  end
end

RSpec.describe Support::Ai::Typing do
  let(:ticket) { create(:ticket) }
  let(:conversation) { ticket.conversation }

  it "appends the indicator to the conversation messages container" do
    expect { described_class.show(ticket) }.to have_broadcasted_to(conversation.to_gid_param).with { |data|
      expect(data).to include("turbo-stream", "append", "support_conversation_#{conversation.id}_messages", ActionView::RecordIdentifier.dom_id(conversation, :typing))
    }
  end

  it "removes the indicator" do
    expect { described_class.hide(ticket) }.to have_broadcasted_to(conversation.to_gid_param).with { |data|
      expect(data).to include("remove", ActionView::RecordIdentifier.dom_id(conversation, :typing))
    }
  end
end

RSpec.describe Support::Ai::Dispatch do
  let(:ticket) { create(:ticket, :ai_analyzing) }

  it "shows typing and enqueues the job" do
    expect { described_class.call(ticket, "user_message", 7) }
      .to have_enqueued_job(Support::AiProcessJob).with(ticket.id, "user_message", 7)
      .and have_broadcasted_to(ticket.conversation.to_gid_param)
  end

  it "swallows enqueue errors, hides typing and reports false" do
    allow(Support::AiProcessJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError, "down")
    expect(Support::Ai::Typing).to receive(:hide).with(ticket)
    expect(described_class.call(ticket, "ticket_created")).to be(false)
  end

  it "does not swallow unrelated errors" do
    allow(Support::AiProcessJob).to receive(:perform_later).and_raise(NoMethodError)
    expect { described_class.call(ticket, "ticket_created") }.to raise_error(NoMethodError)
  end
end

RSpec.describe Support::Ai::HandoffNote do
  let(:ticket) { create(:ticket, :ai_handoff_requested) }
  let(:playbook) { create(:ai_playbook) }

  it "stores the AI summary as an ai note" do
    stub_responder(summarize: ai_result("Summary text"))
    note = described_class.call(ticket: ticket, playbook: playbook, reason: "r")
    expect(note).to have_attributes(kind: "ai", account: nil, body: "Summary text")
  end

  it "falls back to a plain note when the summary fails" do
    stub_responder(summarize: SupportAi::Error.new("nope"))
    note = described_class.call(ticket: ticket, playbook: playbook, reason: "user requested a human")
    expect(note.body).to eq("AI handoff: user requested a human. See conversation.")
  end

  it "falls back when there is no playbook at all" do
    note = described_class.call(ticket: ticket, reason: "x")
    expect(note.body).to eq("AI handoff: x. See conversation.")
  end
end
