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

  it "records a snapshot of the playbook rules" do
    audience = create(:audience, name: "VIPs")
    playbook = create(:ai_playbook, name: "Billing", category_keys: ["billing"], min_priority: 2, audience: audience,
      instructions: "Be kind.", capabilities: %w[search_articles], max_ai_turns: 3)
    run = described_class.call(ticket: ticket, playbook: playbook, trigger: "ticket_created", step: :respond, result: ai_result(respond_output))

    expect(run.playbook_snapshot).to include(
      "name" => "Billing", "mode" => "assist", "capabilities" => ["search_articles"], "instructions" => "Be kind.",
      "max_ai_turns" => 3, "categories" => ["billing"], "min_priority" => 2, "max_priority" => nil,
      "audience" => "VIPs", "is_default" => false
    )
    expect(run.playbook_snapshot.keys).to include("idle_reminder_after_hours", "idle_handoff_after_hours")
  end

  it "records the snapshot on failed runs too" do
    run = described_class.call(ticket: ticket, playbook: playbook, trigger: "user_message", step: :respond, error: SupportAi::Error.new("boom"))
    expect(run.playbook_snapshot).to include("name" => playbook.name)
  end

  it "keeps the snapshot after the playbook is changed or deleted" do
    run = described_class.call(ticket: ticket, playbook: playbook, trigger: "ticket_created", step: :respond, result: ai_result(respond_output))
    name = playbook.name
    playbook.update!(name: "Renamed")
    playbook.destroy!
    expect(run.reload.playbook_id).to be_nil
    expect(run.playbook_snapshot["name"]).to eq(name)
  end

  it "stores an empty snapshot without a playbook" do
    run = described_class.call(ticket: ticket, trigger: :fallback, step: :respond, error: "x")
    expect(run.playbook_snapshot).to eq({})
  end

  it "wraps string output as text" do
    run = described_class.call(ticket: ticket, trigger: :ticket_created, step: :handle, result: ai_result("findings"))
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

RSpec.describe Support::Ai::Dispatch do
  let(:ticket) { create(:ticket, :ai_analyzing) }

  it "enqueues the job" do
    expect { described_class.call(ticket, "user_message", 7) }
      .to have_enqueued_job(Support::AiProcessJob).with(ticket.id, "user_message", 7)
  end

  it "swallows enqueue errors and reports false" do
    allow(Support::AiProcessJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError, "down")
    expect(described_class.call(ticket, "ticket_created")).to be(false)
  end

  it "does not swallow unrelated errors" do
    allow(Support::AiProcessJob).to receive(:perform_later).and_raise(NoMethodError)
    expect { described_class.call(ticket, "ticket_created") }.to raise_error(NoMethodError)
  end
end
