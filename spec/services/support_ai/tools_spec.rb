require "rails_helper"

RSpec.describe "SupportAi tools" do
  let(:requester) { create(:account, :verified, :with_role) }
  let(:ticket) { create(:ticket, created: requester, category: :billing, title: "Invoice charged twice") }

  describe SupportAi::Tools::SearchArticles, "registry" do
    it "uses short snake_case tool names" do
      expect(SupportAi::Tools::SearchArticles.new(ticket: ticket).name).to eq("search_articles")
    end

    it "is wired into the registry for every tool" do
      classes = Support::AiCapabilities.all.filter_map(&:tool_class)
      expect(classes).to eq(%w[SupportAi::Tools::SearchArticles])
      expect(classes.map(&:constantize)).to all(be < RubyLLM::Tool)
    end
  end

  describe SupportAi::Tools::SearchArticles do
    it "returns published articles, any category, with locale" do
      hit = create(:article, :published, category: :account_access, title: "Fix double charge", summary: "refund steps")
      create(:article, category: :billing, title: "Draft double charge")

      articles = described_class.new(ticket: ticket).call(query: "double charge")[:articles]

      expect(articles).to eq([{id: hit.id, title: "Fix double charge", summary: "refund steps", slug: hit.slug, locale: "en"}])
    end

    it "finds an account_access article for a technical_issue ticket" do
      tech = create(:ticket, created: requester, category: :technical_issue)
      hit = create(:article, :published, category: :account_access, title: "How to reset your password")

      articles = described_class.new(ticket: tech).call(query: "change password")[:articles]

      expect(articles.pluck(:id)).to eq([hit.id])
    end

    it "searches the given locale first, then any locale" do
      en = create(:article, :published, title: "Password help")
      es = create(:article, :published, :spanish, title: "Password ayuda")
      only_en = create(:article, :published, title: "Invoices guide")

      expect(described_class.new(ticket: ticket, locale: "es").call(query: "password")[:articles].pluck(:id)).to eq([es.id])
      expect(described_class.new(ticket: ticket, locale: "es").call(query: "invoices")[:articles].pluck(:id)).to eq([only_en.id])
      expect(described_class.new(ticket: ticket, locale: "en").call(query: "password")[:articles].pluck(:id)).to eq([en.id])
    end

    it "records queries and found ids on the budget once, even for cached repeats" do
      hit = create(:article, :published, title: "Password help")
      budget = SupportAi::ToolBudget.new
      tool = described_class.new(ticket: ticket, budget: budget)

      2.times { tool.call(query: "password") }
      tool.call(query: "nothing matches zzzz")

      expect(budget.searched_queries).to eq(["password", "nothing matches zzzz"])
      expect(budget.found_article_ids).to eq([hit.id])
      expect(budget).to be_articles_found
    end

    it "works without a budget" do
      expect(described_class.new(ticket: ticket).call(query: "zzzz")).to eq(articles: [])
    end
  end
end
