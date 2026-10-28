require "rails_helper"

RSpec.describe SupportAiConfig do
  it "defaults to disabled with sane limits when the environment sets nothing" do
    with_env("SUPPORT_AI_ENABLED" => nil, "SUPPORT_AI_HISTORY_LIMIT" => nil) do
      config = described_class.new
      expect(config.enabled).to be(false)
      expect(config.model).to eq("minimax/minimax-m3.1-flash:free")
      expect(config.vision_model).to be_present
      expect(config.temperature).to eq(0.3)
      expect(config.history_limit).to eq(30)
      expect(config.max_tool_calls).to eq(10)
      expect(config.timeout).to eq(60)
      expect(config.untrusted_marker).to eq("UNTRUSTED")
    end
  end

  it "reads the untrusted marker from SUPPORT_AI_UNTRUSTED_MARKER" do
    with_env("SUPPORT_AI_UNTRUSTED_MARKER" => "DATA") { expect(described_class.new.untrusted_marker).to eq("DATA") }
  end

  it "can be overridden from the environment" do
    with_env("SUPPORT_AI_ENABLED" => "true", "SUPPORT_AI_HISTORY_LIMIT" => "5") do
      config = described_class.new
      expect(config.enabled).to be(true)
      expect(config.history_limit).to eq(5)
    end
  end

  def with_env(vars)
    old = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
