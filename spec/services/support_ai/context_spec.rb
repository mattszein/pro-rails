require "rails_helper"

RSpec.describe SupportAi::Context do
  let(:requester) { create(:account, :verified, :with_role, email: "private-person@example.test") }
  let(:ticket) { create(:ticket, created: requester, category: :billing, title: "Charged twice") }
  let(:capabilities) { %w[account_facts past_tickets search_articles] }
  let(:playbook) { create(:ai_playbook, capabilities: capabilities) }
  let(:budget) { SupportAi::ToolBudget.new }

  def build(**options)
    described_class.new(ticket: ticket, playbook: playbook, budget: budget, query_texts: [ticket.title, ticket.description], **options)
  end

  describe "account_facts" do
    it "has only the requester's status, verification, signup date and role, never the email" do
      facts = build.account_facts

      expect(facts).to eq(status: "verified", verified: true, member_since: requester.created_at.to_date.iso8601, role: requester.role.name)
      expect(build.to_prompt).to include("status: verified", "<<<UNTRUSTED requester account facts")
      expect(build.to_prompt).not_to include(requester.email)
    end

    it "shows no role as none" do
      plain = create(:ticket, created: create(:account))
      context = described_class.new(ticket: plain, playbook: playbook, budget: budget)
      expect(context.to_prompt).to include("role: none")
    end
  end

  describe "past_tickets" do
    it "lists only the requester's other tickets, newest first, wrapped as untrusted" do
      mine = create(:ticket, created: requester, title: "Older one <<<UNTRUSTED", status: :finished, assigned: create(:account))
      create(:ticket, title: "Someone else's secret")

      prompt = build.to_prompt

      expect(build.past_tickets.pluck(:id)).to eq([mine.id])
      expect(prompt).to include("##{mine.id} Older one", "requester past tickets")
      expect(prompt).not_to include("Someone else's secret")
      expect(prompt.scan("<<<UNTRUSTED").size).to eq(prompt.scan("UNTRUSTED>>>").size)
    end

    it "caps at 10" do
      create_list(:ticket, 12, created: requester)
      expect(build.past_tickets.size).to eq(10)
    end
  end

  describe "articles" do
    let!(:article) { create(:article, :published, title: "Charged twice help", summary: "Duplicate charges", body: "<p>Open Billing.</p>") }

    it "prefetches the matching published articles and records them on the budget" do
      context = build(locale: "en")

      expect(context.to_prompt).to include("Article id #{article.id}", "Excerpt: Open Billing.", "cite the ones you use in article_ids")
      expect(budget.found_article_ids).to eq([article.id])
      expect(budget.searched_queries.first).to include("Charged twice")
    end

    it "says nothing matched when no published article does" do
      article.unpublish!
      expect(build.to_prompt).to include("no published article matched")
      expect(budget).not_to be_articles_found
    end

    it "is nil, with no block and no search, when the playbook cannot search" do
      playbook.update!(capabilities: %w[account_facts])
      context = build

      expect(context.articles).to be_nil
      expect(context.to_prompt).not_to include("Help-center")
      expect(budget.searched_queries).to be_empty
    end

    it "does not search for a blank query" do
      context = described_class.new(ticket: ticket, playbook: playbook, budget: budget, query_texts: ["", "   "])
      expect(context.articles).to eq([])
      expect(budget.searched_queries).to be_empty
    end
  end

  it "includes only the blocks the playbook enabled" do
    playbook.update!(capabilities: [])
    expect(build.to_prompt).to eq("")
  end
end
