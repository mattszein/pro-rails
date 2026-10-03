require "rails_helper"

RSpec.describe Support::Article, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:article)).to be_valid
    end

    it "requires title, summary and locale" do
      article = build(:article, title: nil, summary: nil, locale: nil)
      expect(article).not_to be_valid
      expect(article.errors.attribute_names).to include(:title, :summary, :locale)
    end

    it "rejects unsupported locales" do
      expect(build(:article, locale: "fr")).not_to be_valid
    end

    it "accepts es" do
      expect(build(:article, :spanish)).to be_valid
    end

    it "rejects slugs that normalize to nothing" do
      expect(build(:article, slug: "!!!", title: "???")).not_to be_valid
    end

    it "requires a unique slug per locale" do
      create(:article, slug: "reset-password")
      expect(build(:article, slug: "reset-password")).not_to be_valid
      expect(build(:article, :spanish, slug: "reset-password")).to be_valid
    end

    it "allows a nil category (general)" do
      expect(build(:article, :general)).to be_valid
    end

    it "rejects an unknown status" do
      expect { build(:article, status: :archived) }.not_to raise_error
      expect(build(:article, status: :archived)).not_to be_valid
    end

    it "does not require an author" do
      expect(build(:article, author: nil)).to be_valid
    end
  end

  describe "category" do
    it "shares values with Support::Ticket" do
      expect(described_class.categories).to eq(Support::Ticket.categories)
    end
  end

  describe "slug normalization" do
    it "derives the slug from the title when blank" do
      article = build(:article, title: "How to Reset Your Password!", slug: "")
      article.valid?
      expect(article.slug).to eq("how-to-reset-your-password")
    end

    it "parameterizes a provided slug" do
      article = build(:article, slug: "My Slug")
      article.valid?
      expect(article.slug).to eq("my-slug")
    end
  end

  describe "search_text" do
    it "is populated from the body on save" do
      article = create(:article, body: "<p>Hello <strong>world</strong></p>")
      expect(article.reload.search_text).to eq("Hello world")
    end

    it "updates when the body changes" do
      article = create(:article, body: "<p>old</p>")
      article.update!(body: "<p>new content</p>")
      expect(article.reload.search_text).to eq("new content")
    end
  end

  describe "transitions" do
    it "publishes a draft" do
      article = create(:article)
      article.publish!
      expect(article).to be_published
      expect(article.published_at).to be_present
    end

    it "raises when publishing a published article" do
      expect { create(:article, :published).publish! }
        .to raise_error(Support::Article::InvalidTransition)
    end

    it "unpublishes a published article" do
      article = create(:article, :published)
      article.unpublish!
      expect(article).to be_draft
    end

    it "raises when unpublishing a draft" do
      expect { create(:article).unpublish! }
        .to raise_error(Support::Article::InvalidTransition)
    end
  end

  describe ".search" do
    it "returns none for a blank query" do
      create(:article, title: "Password reset")
      expect(described_class.search("")).to be_empty
      expect(described_class.search(nil)).to be_empty
    end

    it "matches title, summary and body" do
      by_title = create(:article, title: "Invoices explained")
      by_summary = create(:article, summary: "All about invoices")
      by_body = create(:article, body: "<p>Download your invoices here</p>")
      create(:article, title: "Unrelated")

      expect(described_class.search("invoices")).to contain_exactly(by_title, by_summary, by_body)
    end

    it "ranks title matches above summary above body" do
      body = create(:article, title: "Other", summary: "Nothing", body: "<p>refund details</p>")
      summary = create(:article, title: "Other two", summary: "refund info", body: "<p>x</p>")
      title = create(:article, title: "Refund policy", summary: "Nothing", body: "<p>x</p>")

      expect(described_class.search("refund")).to eq([title, summary, body])
    end

    it "supports websearch syntax" do
      keep = create(:article, title: "Billing cards")
      create(:article, title: "Billing invoices")

      expect(described_class.search("billing -invoices")).to eq([keep])
    end

    it "filters by locale when given" do
      en = create(:article, title: "Password help")
      es = create(:article, :spanish, title: "Password ayuda")

      expect(described_class.search("password", locale: "es")).to eq([es])
      expect(described_class.search("password", locale: :en)).to eq([en])
      expect(described_class.search("password")).to contain_exactly(en, es)
    end

    it "includes the category and general articles but not other categories" do
      billing = create(:article, title: "Help billing", category: :billing)
      general = create(:article, :general, title: "Help general")
      create(:article, title: "Help access", category: :account_access)

      expect(described_class.search("help", category: :billing)).to contain_exactly(billing, general)
    end

    it "respects the limit" do
      create_list(:article, 3, title: "Setup guide")
      expect(described_class.search("setup", limit: 2).to_a.size).to eq(2)
    end

    it "only returns published articles when chained with .published" do
      draft = create(:article, title: "Guide draft")
      published = create(:article, :published, title: "Guide live")

      expect(described_class.published.search("guide")).to eq([published])
      expect(described_class.search("guide")).to contain_exactly(draft, published)
    end

    it "is safe against SQL-like input" do
      create(:article, title: "Hello")
      expect { described_class.search("'; DROP TABLE support_articles; --").to_a }.not_to raise_error
    end
  end

  describe ".search_title" do
    it "matches titles case-insensitively" do
      match = create(:article, title: "Reset Password")
      create(:article, title: "Billing")
      expect(described_class.search_title("reset")).to eq([match])
    end
  end
end
