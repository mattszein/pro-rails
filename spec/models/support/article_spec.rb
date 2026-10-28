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

    it "has a real general category by default" do
      expect(build(:article, :general)).to be_valid
      expect(described_class.new.category).to eq("general")
      expect(build(:article, category: nil)).not_to be_valid
    end

    it "rejects an unknown status" do
      expect { build(:article, status: :archived) }.not_to raise_error
      expect(build(:article, status: :archived)).not_to be_valid
    end

    it "does not require an author" do
      expect(build(:article, author: nil)).to be_valid
    end
  end

  describe "#excerpt" do
    it "returns the squished plain-text body" do
      article = create(:article, body: "<p>One  two</p><p>three</p>")
      expect(article.excerpt).to eq("One two three")
    end

    it "truncates with an ellipsis" do
      article = create(:article, body: "<p>#{"word " * 500}</p>")
      expect(article.excerpt(50).length).to eq(50)
      expect(article.excerpt(50)).to end_with("...")
    end

    it "is empty for a blank body" do
      expect(build(:article, body: "").excerpt).to eq("")
    end
  end

  describe "category" do
    it "shares values with Support::Ticket and adds general" do
      expect(described_class.categories).to eq(Support::Ticket.categories.merge("general" => described_class::GENERAL_CATEGORY))
      expect(Support::Ticket.categories.values).not_to include(described_class::GENERAL_CATEGORY)
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

    describe ".published_search" do
      it "returns only published articles for the locale, with general ones for the category" do
        live = create(:article, :published, title: "Billing guide", category: :billing)
        general = create(:article, :published, :general, title: "Billing basics")
        create(:article, title: "Billing draft", category: :billing)
        create(:article, :published, :spanish, title: "Billing guia", category: :billing)
        create(:article, :published, title: "Billing other", category: :account_access)

        expect(described_class.published_search("billing", locale: :en, category: :billing)).to contain_exactly(live, general)
      end

      it "breaks relevance ties by newest publication" do
        older = create(:article, title: "Export data", published_at: 2.days.ago, status: :published)
        newer = create(:article, title: "Export data", published_at: 1.day.ago, status: :published)

        expect(described_class.published_search("export data").to_a).to eq([newer, older])
      end
    end

    describe "OR fallback" do
      it "keeps an AND hit unchanged and does not widen it" do
        both = create(:article, title: "Reset password steps")
        create(:article, title: "Password billing")

        expect(described_class.search("reset password")).to eq([both])
      end

      it "falls back to an OR of terms when no article has every word" do
        reset = create(:article, :published, title: "How to reset your password")
        create(:article, :published, title: "Invoices")

        expect(described_class.search("change password", published_only: true)).to eq([reset])
      end

      it "excludes body-only OR matches but keeps title and summary matches" do
        title = create(:article, title: "Change your email", summary: "Nothing", body: "<p>x</p>")
        summary = create(:article, title: "Other two", summary: "Update your password", body: "<p>x</p>")
        create(:article, title: "Roadmap", summary: "Nothing", body: "<p>We ship changes monthly</p>")

        expect(described_class.search("change password")).to contain_exactly(title, summary)
      end

      it "returns only the password article for seeded-style fixtures" do
        reset = create(:article, :published, title: "How to reset your password", summary: "Recover access", body: "<p>Use the link</p>")
        create(:article, :published, title: "Where to find the roadmap", summary: "See upcoming work", body: "<p>Read about changes</p>")

        expect(described_class.search("change password", published_only: true)).to eq([reset])
      end

      it "matches by prefix" do
        reset = create(:article, title: "Password recovery")
        expect(described_class.search("recov nonsenseword")).to eq([reset])
      end

      it "applies the locale and category filters in both modes" do
        en = create(:article, title: "Password help", category: :account_access)
        create(:article, :spanish, title: "Password ayuda", category: :account_access)
        create(:article, title: "Password billing", category: :billing)

        expect(described_class.search("change password", locale: :en, category: :account_access)).to eq([en])
        expect(described_class.search("password", locale: :en, category: :account_access)).to eq([en])
      end

      it "is not suppressed by a draft-only AND match when published_only" do
        create(:article, title: "Change password draft")
        live = create(:article, :published, title: "Password reset")

        expect(described_class.search("change password", published_only: true)).to eq([live])
        expect(described_class.search("change password", published_only: true).published).to eq([live])
      end

      it "decides on the chained scope when called on a relation" do
        create(:article, title: "Change password draft")
        live = create(:article, :published, title: "Password reset")

        expect(described_class.published.search("change password")).to eq([live])
      end

      it "treats tsquery syntax as plain text" do
        hit = create(:article, title: "Password help")

        expect { described_class.search("password' | !secret & (x").to_a }.not_to raise_error
        expect(described_class.search("zzz' | !secret & (x:*")).to be_empty
        expect(described_class.search("nomatch' | !secret & (password")).to eq([hit])
      end

      it "returns none without usable terms" do
        create(:article, title: "Go to it")
        expect(described_class.search("a b !! ??")).to be_empty
        expect(described_class.search("zz")).to be_empty
      end

      it "honors limit in fallback mode and limit: nil" do
        create_list(:article, 3, title: "Setup guide")
        expect(described_class.search("setup nomatchword", limit: 2).to_a.size).to eq(2)
        expect(described_class.search("setup nomatchword", limit: nil).to_a.size).to eq(3)
      end
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
