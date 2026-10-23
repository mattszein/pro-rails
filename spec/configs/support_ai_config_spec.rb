require "rails_helper"

RSpec.describe SupportAiConfig do
  it "defaults to disabled with sane limits" do
    expect(described_class.enabled).to be(false)
    expect(described_class.model).to eq("minimax/minimax-m3.1-flash:free")
    expect(described_class.vision_model).to be_present
    expect(described_class.temperature).to eq(0.3)
    expect(described_class.history_limit).to eq(30)
    expect(described_class.max_tool_calls).to eq(10)
    expect(described_class.timeout).to eq(60)
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
