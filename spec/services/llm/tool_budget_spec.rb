require "rails_helper"

RSpec.describe Llm::ToolBudget do
  subject(:budget) { described_class.new(limit: 2) }

  it "records calls with name and arguments" do
    budget.record(:account_facts, {a: 1})
    expect(budget.calls).to eq([{name: "account_facts", arguments: {a: 1}}])
  end

  it "defaults the limit to DEFAULT_LIMIT" do
    expect(described_class.new.limit).to eq(described_class::DEFAULT_LIMIT)
  end

  it "runs the block and counts executed calls" do
    expect(budget.run("t", {q: 1}) { "one" }).to eq("one")
    expect(budget).not_to be_exhausted
    budget.run("t", {q: 2}) { "two" }
    expect(budget).to be_exhausted
  end

  it "serves identical calls from the cache without counting them" do
    runs = 0
    3.times { budget.run("t", {"q" => 1}) { runs += 1 } }
    budget.run("t", {q: 1}) { runs += 1 }

    expect(runs).to eq(1)
    expect(budget).not_to be_exhausted
  end

  it "returns the limit message without running once exhausted" do
    budget.run("t", {q: 1}) { 1 }
    budget.run("t", {q: 2}) { 2 }

    result = budget.run("t", {q: 3}) { raise "must not run" }

    expect(result).to eq(error: described_class::LIMIT_MESSAGE)
  end

  it "still returns cached results once exhausted" do
    budget.run("t", {q: 1}) { 1 }
    budget.run("t", {q: 2}) { 2 }
    expect(budget.run("t", {q: 1}) { raise "no" }).to eq(1)
  end

  it "trips the backstop after repeated refused calls" do
    budget.run("t", {q: 1}) { 1 }
    budget.run("t", {q: 2}) { 2 }
    3.times { |i| budget.run("t", {q: 10 + i}) { 0 } }

    expect(budget).to be_backstop_hit
  end
end
