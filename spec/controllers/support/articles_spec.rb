require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

RSpec.describe Support::ArticlesController, type: :controller do
  let(:account) { create(:account, :verified) }
  render_views
  let(:articles) { controller.instance_variable_get(:@articles) }

  describe "GET #index" do
    context "when not logged in" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in" do
      before { login_user(account) }

      it "responds successfully" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "is authorized" do
        expect { get :index }.to be_authorized_to(:index?, :article).with(Support::ArticlePolicy).with_context(user: account)
      end

      it "lists only published articles" do
        published = create(:article, :published)
        create(:article)
        get :index
        expect(articles).to contain_exactly(published)
      end

      it "paginates" do
        get :index
        expect(controller.instance_variable_get(:@pagy)).to be_a(Pagy)
      end

      it "orders by published_at desc" do
        old = create(:article, :published, published_at: 2.days.ago)
        recent = create(:article, :published, published_at: 1.hour.ago)
        get :index
        expect(articles.to_a).to eq([recent, old])
      end

      it "only lists the current locale" do
        en = create(:article, :published)
        create(:article, :published, :spanish)
        get :index
        expect(articles).to contain_exactly(en)
      end

      it "lists spanish articles under the es locale" do
        create(:article, :published)
        es = create(:article, :published, :spanish)
        get :index, params: {locale: "es"}
        expect(articles).to contain_exactly(es)
      end

      it "searches published articles only" do
        hit = create(:article, :published, title: "Reset password", summary: "How to reset your password")
        create(:article, title: "Reset password draft", summary: "password")
        create(:article, :published, title: "Billing", summary: "invoices")
        get :index, params: {q: "password"}
        expect(articles).to contain_exactly(hit)
      end

      it "returns nothing for a search with no match" do
        create(:article, :published)
        get :index, params: {q: "zzzxyz"}
        expect(articles).to be_empty
      end

      it "filters by category" do
        billing = create(:article, :published, category: :billing)
        create(:article, :published, category: :other)
        get :index, params: {category: "billing"}
        expect(articles).to contain_exactly(billing)
      end

      it "filters general articles" do
        general = create(:article, :published, :general)
        create(:article, :published, category: :billing)
        get :index, params: {category: "general"}
        expect(articles).to contain_exactly(general)
      end

      it "ignores an unknown category" do
        a = create(:article, :published)
        get :index, params: {category: "bogus"}
        expect(articles).to contain_exactly(a)
      end

      it "combines search and category" do
        hit = create(:article, :published, category: :billing, title: "Invoice help")
        create(:article, :published, category: :other, title: "Invoice other")
        get :index, params: {q: "invoice", category: "billing"}
        expect(articles).to contain_exactly(hit)
      end
    end
  end

  describe "GET #suggestions" do
    context "when not logged in" do
      it "redirects to login" do
        get :suggestions, params: {q: "password"}
        expect(response).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in" do
      before { login_user(account) }

      it "is authorized" do
        expect { get :suggestions, params: {q: "password"} }.to be_authorized_to(:index?, :article).with(Support::ArticlePolicy).with_context(user: account)
      end

      it "renders published matches in a frame without layout" do
        hit = create(:article, :published, title: "Reset password", summary: "How to reset it")
        get :suggestions, params: {q: "password"}
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="help_suggestions"', I18n.t("support.articles.suggestions_title"), "Reset password", "How to reset it")
        expect(response.body).to include(%(href="#{help_article_path(slug: hit.slug)}"), 'target="_blank"')
        expect(response.body).not_to include("<html")
      end

      it "excludes drafts" do
        create(:article, title: "Draft password", summary: "password")
        get :suggestions, params: {q: "password"}
        expect(response.body).not_to include("Draft password")
        expect(response.body).not_to include(I18n.t("support.articles.suggestions_title"))
      end

      it "returns at most 3" do
        5.times { |i| create(:article, :published, title: "Password tip #{i}", slug: "pw-#{i}") }
        get :suggestions, params: {q: "password"}
        expect(controller.instance_variable_get(:@articles).size).to eq(3)
      end

      it "is scoped to the current locale" do
        create(:article, :published, :spanish, title: "Password es", slug: "pw-es")
        en = create(:article, :published, title: "Password en", slug: "pw-en")
        get :suggestions, params: {q: "password"}
        expect(controller.instance_variable_get(:@articles)).to contain_exactly(en)
      end

      it "filters by category, keeping general articles" do
        billing = create(:article, :published, category: :billing, title: "Password billing", slug: "pw-b")
        general = create(:article, :published, :general, title: "Password general", slug: "pw-g")
        create(:article, :published, category: :other, title: "Password other", slug: "pw-o")
        get :suggestions, params: {q: "password", category: "billing"}
        expect(controller.instance_variable_get(:@articles)).to contain_exactly(billing, general)
      end

      it "ignores an unknown category" do
        a = create(:article, :published, title: "Password")
        get :suggestions, params: {q: "password", category: "bogus"}
        expect(controller.instance_variable_get(:@articles)).to contain_exactly(a)
      end

      it "renders an empty frame for a blank query" do
        create(:article, :published, title: "Password")
        get :suggestions
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="help_suggestions"')
        expect(response.body).not_to include(I18n.t("support.articles.suggestions_title"))
      end

      it "renders an empty frame for a short query" do
        create(:article, :published, title: "Ab password")
        get :suggestions, params: {q: "ab"}
        expect(controller.instance_variable_get(:@articles)).to be_empty
      end

      it "renders an empty frame when nothing matches" do
        get :suggestions, params: {q: "zzzxyz"}
        expect(response.body).to include('id="help_suggestions"')
        expect(response.body).not_to include(I18n.t("support.articles.suggestions_title"))
      end
    end
  end

  describe "GET #show" do
    context "when not logged in" do
      it "redirects to login" do
        article = create(:article, :published)
        get :show, params: {slug: article.slug}
        expect(response).to redirect_to(rodauth.login_path)
      end
    end

    context "when logged in" do
      before { login_user(account) }

      it "shows a published article" do
        article = create(:article, :published)
        get :show, params: {slug: article.slug}
        expect(response).to have_http_status(:ok)
        expect(controller.instance_variable_get(:@article)).to eq(article)
      end

      it "is authorized" do
        article = create(:article, :published)
        expect { get :show, params: {slug: article.slug} }.to be_authorized_to(:show?, article).with(Support::ArticlePolicy)
      end

      it "does not reach a draft" do
        draft = create(:article)
        get :show, params: {slug: draft.slug}
        expect(response).not_to have_http_status(:ok)
        expect(flash[:alert]).to eq(I18n.t("errors.record_not_found"))
      end

      it "prefers the current locale for a shared slug" do
        create(:article, :published, :spanish, slug: "shared")
        en = create(:article, :published, slug: "shared")
        get :show, params: {slug: "shared"}
        expect(controller.instance_variable_get(:@article)).to eq(en)
      end

      it "falls back to another locale" do
        es = create(:article, :published, :spanish, slug: "solo-es")
        get :show, params: {slug: "solo-es"}
        expect(controller.instance_variable_get(:@article)).to eq(es)
      end

      it "does not fall back to a draft in another locale" do
        create(:article, :spanish, slug: "draft-es")
        get :show, params: {slug: "draft-es"}
        expect(response).not_to have_http_status(:ok)
      end
    end
  end
end
