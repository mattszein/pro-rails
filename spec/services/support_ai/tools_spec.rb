require "rails_helper"

RSpec.describe "SupportAi tools" do
  let(:requester) { create(:account, :verified, :with_role) }
  let(:ticket) { create(:ticket, created: requester, category: :billing, title: "Invoice charged twice") }

  describe SupportAi::Tools::Base do
    it "uses short snake_case tool names" do
      expect(SupportAi::Tools::AccountFacts.new(ticket: ticket).name).to eq("account_facts")
    end

    it "is wired into the registry for every tool" do
      classes = SupportAi::Capabilities::Registry.all.filter_map(&:tool_class)
      expect(classes).to match_array(%w[
        SupportAi::Tools::AccountFacts SupportAi::Tools::PastTickets SupportAi::Tools::SimilarTickets
        SupportAi::Tools::SearchArticles SupportAi::Tools::SuggestArticles SupportAi::Tools::ProposeResolution
        SupportAi::Tools::RequestHuman
      ])
      expect(classes.map(&:constantize)).to all(be < RubyLLM::Tool)
    end
  end

  describe SupportAi::Tools::AccountFacts do
    it "returns only requester facts, never email or credentials" do
      result = described_class.new(ticket: ticket).call

      expect(result).to eq(status: "verified", verified: true, member_since: requester.created_at.to_date.iso8601, role: requester.role.name)
      expect(result.to_json).not_to include(requester.email)
      expect(result.keys).not_to include(:email, :password_hash)
    end

    it "returns a nil role for accounts without one" do
      plain = create(:ticket, created: create(:account))
      expect(described_class.new(ticket: plain).call[:role]).to be_nil
    end
  end

  describe SupportAi::Tools::PastTickets do
    it "lists only the requester's other tickets" do
      mine = create(:ticket, created: requester, title: "Older one", status: :finished, assigned: create(:account))
      create(:ticket, title: "Someone else's secret")

      tickets = described_class.new(ticket: ticket).call[:tickets]

      expect(tickets.pluck(:id)).to eq([mine.id])
      expect(tickets.first).to include(title: "Older one", finished: true, status: "finished")
      expect(tickets.pluck(:id)).not_to include(ticket.id)
    end

    it "caps at 10" do
      create_list(:ticket, 12, created: requester)
      expect(described_class.new(ticket: ticket).call[:tickets].size).to eq(10)
    end
  end

  describe SupportAi::Tools::SimilarTickets do
    let(:other) { create(:account, email: "private-person@example.test") }

    it "returns only title, category and month of other accounts' finished tickets in the same category" do
      match = create(:ticket, :finished, created: other, category: :billing, title: "Invoice problem", description: "SECRET DESC")
      create(:ticket, :finished, created: other, category: :technical_issue, title: "Invoice crash")
      create(:ticket, created: other, category: :billing, title: "Invoice still open")
      create(:ticket, :finished, created: requester, category: :billing, title: "Invoice mine")

      result = described_class.new(ticket: ticket).call(query: "invoice")

      expect(result[:tickets]).to eq([{title: "Invoice problem", category: "billing", month: match.created_at.strftime("%Y-%m")}])
      expect(result.to_json).not_to include("SECRET DESC", other.email, "created")
    end

    it "falls back to the ticket title when the query has no usable words" do
      create(:ticket, :finished, created: other, category: :billing, title: "Invoice problem")
      expect(described_class.new(ticket: ticket).call(query: "a")[:tickets].size).to eq(1)
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

  describe "action tools" do
    let(:collector) { SupportAi::ActionCollector.new }

    it "RequestHuman records the reason and does not touch the database" do
      expect { SupportAi::Tools::RequestHuman.new(ticket: ticket, collector: collector).call(reason: "billing change") }
        .not_to change { ticket.reload.attributes }
      expect(collector).to have_attributes(handoff: true, handoff_reason: "billing change")
    end

    it "ProposeResolution flags the collector" do
      SupportAi::Tools::ProposeResolution.new(ticket: ticket, collector: collector).call
      expect(collector.resolution_proposed).to be(true)
    end

    it "SuggestArticles drops unknown, draft and non-numeric ids and caps at three" do
      published = create_list(:article, 4, :published)
      draft = create(:article)

      SupportAi::Tools::SuggestArticles.new(ticket: ticket, collector: collector)
        .call(article_ids: [draft.id, "junk", 0] + published.map(&:id))

      expect(collector.article_ids).to eq(published.first(3).map(&:id))
    end
  end
end
