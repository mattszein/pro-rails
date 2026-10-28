# Builders and stubs for specs of the AI workflows. The Responder is always stubbed:
# these specs never reach the network.
module SupportAiWorkflowHelpers
  def ai_result(output, model: "stub-model", input_tokens: 10, output_tokens: 5, latency_ms: 120, tool_calls: [], transcript: [])
    SupportAi::Result.new(output: output, model: model, input_tokens: input_tokens, output_tokens: output_tokens, latency_ms: latency_ms, tool_calls: tool_calls, transcript: transcript)
  end

  def triage_output(**overrides)
    {category: "account_access", priority: 3, sentiment: "neutral", language: "en", summary: "Cannot log in", escalate: false, escalate_reason: ""}.merge(overrides)
  end

  def respond_output(**overrides)
    {reply: "Try resetting your password.", article_ids: [], resolution_proposed: false, handoff_requested: false, handoff_reason: ""}.merge(overrides)
  end

  # Shape of Responder#handle output .
  def handle_output(**overrides)
    {findings: "Request: reset password.\nContext: none\nNext step: send the reset link.", reply: "Try resetting your password.", article_ids: [], resolution_proposed: false, handoff_requested: false, handoff_reason: "", kb_gap: false, kb_queries: []}.merge(overrides)
  end

  # Returns the instance_double so examples can set further expectations.
  def stub_responder(triage: nil, handle: nil, respond: nil)
    responder = instance_double(SupportAi::Responder)
    {triage: triage, handle: handle, respond: respond}.each do |step, value|
      next if value.nil?

      if value.is_a?(Exception) || (value.is_a?(Class) && value <= Exception)
        allow(responder).to receive(step).and_raise(value)
      else
        allow(responder).to receive(step).and_return(value)
      end
    end
    allow(SupportAi::Responder).to receive(:new).and_return(responder)
    responder
  end
end

RSpec.configure do |config|
  config.include SupportAiWorkflowHelpers
end
