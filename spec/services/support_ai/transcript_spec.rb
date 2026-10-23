require "rails_helper"

RSpec.describe SupportAi::Transcript do
  def message(**attrs) = RubyLLM::Message.new({role: :user, content: "hi"}.merge(attrs))

  it "normalizes roles, string content and tool results" do
    entries = described_class.build([message(role: :system, content: "rules"), message(role: :tool, content: "ok", tool_call_id: "c1")])

    expect(entries).to eq([
      {role: "system", content: "rules", tool_calls: [], tool_call_id: nil},
      {role: "tool", content: "ok", tool_calls: [], tool_call_id: "c1"}
    ])
  end

  it "lists assistant tool calls" do
    call = RubyLLM::ToolCall.new(id: "c1", name: "search_articles", arguments: {"query" => "x"})
    entry = described_class.build([message(role: :assistant, content: nil, tool_calls: {"c1" => call})]).first

    expect(entry[:content]).to eq("")
    expect(entry[:tool_calls]).to eq([{id: "c1", name: "search_articles", arguments: {"query" => "x"}}])
  end

  it "serializes Hash content as JSON" do
    allow(RubyLLM::Message).to receive(:new).and_call_original
    msg = instance_double(RubyLLM::Message, role: :assistant, content: {"a" => 1}, tool_calls: nil, tool_call_id: nil, attachments: [])
    expect(described_class.build([msg]).first[:content]).to eq('{"a":1}')
  end

  it "records attachments by filename only" do
    attachment = instance_double(RubyLLM::Attachment, type: :image, filename: "shot.png")
    msg = instance_double(RubyLLM::Message, role: :user, content: "look", tool_calls: nil, tool_call_id: nil, attachments: [attachment])

    expect(described_class.build([msg]).first[:content]).to eq("look\n[image: shot.png]")
  end

  it "truncates long content" do
    entry = described_class.build([message(content: "a" * 25_000)]).first

    expect(entry[:content].length).to eq(described_class::MAX_CONTENT + described_class::MARKER.length)
    expect(entry[:content]).to end_with(described_class::MARKER)
  end
end
