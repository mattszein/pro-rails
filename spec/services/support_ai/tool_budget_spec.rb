require "rails_helper"

RSpec.describe SupportAi::ToolBudget do
  it "is an Llm::ToolBudget whose limit defaults to SupportAiConfig.max_tool_calls" do
    expect(described_class.new).to be_a(Llm::ToolBudget)
    expect(described_class.new.limit).to eq(SupportAiConfig.max_tool_calls)
    expect(described_class.new(limit: 2).limit).to eq(2)
  end

  it "records searched queries and found article ids uniquely, in order" do
    budget = described_class.new
    expect(budget).not_to be_articles_found
    budget.note_search(query: "a", article_ids: [])
    budget.note_search(query: "b", article_ids: [2, 1])
    budget.note_search(query: "a", article_ids: [1, 3])

    expect(budget.searched_queries).to eq(%w[a b])
    expect(budget.found_article_ids).to eq([2, 1, 3])
    expect(budget).to be_articles_found
  end
end
