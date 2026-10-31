require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::ArticlesController, type: :controller do
  include_context "user and permissions adminit"
  render_views

  let(:permitted) { article_permission }

  describe "GET #index" do
    subject { get :index }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Support::Article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "paginates results" do
        subject
        expect(controller.instance_variable_get(:@pagy)).to be_a(Pagy)
      end

      context "with sort params" do
        let!(:old_article) { create(:article, title: "Zebra", created_at: 2.days.ago) }
        let!(:new_article) { create(:article, title: "Apple", created_at: 1.hour.ago) }

        it "sorts by created_at asc" do
          get :index, params: {sort: "created_at", direction: "asc"}
          expect(controller.instance_variable_get(:@articles).first).to eq(old_article)
        end

        it "sorts by title asc" do
          get :index, params: {sort: "title", direction: "asc"}
          expect(controller.instance_variable_get(:@articles).first).to eq(new_article)
        end

        it "ignores invalid sort params" do
          expect { get :index, params: {sort: "malicious_column", direction: "asc"} }.not_to raise_error
        end
      end

      context "with filter params" do
        let!(:billing_draft) { create(:article, title: "Refund policy", category: :billing) }
        let!(:spanish_published) { create(:article, :published, :spanish, title: "Acceso", category: :account_access) }
        let!(:general) { create(:article, :general, title: "Welcome") }

        def listed(filter)
          get :index, params: {filter: filter}
          controller.instance_variable_get(:@articles).to_a
        end

        it "filters by category" do
          expect(listed({category: "billing"})).to contain_exactly(billing_draft)
        end

        it "filters by locale" do
          expect(listed({locale: "es"})).to contain_exactly(spanish_published)
        end

        it "filters by status" do
          expect(listed({status: "published"})).to contain_exactly(spanish_published)
        end

        it "searches by title" do
          expect(listed({search: "refund"})).to contain_exactly(billing_draft)
        end

        it "ignores filter params that aren't declared on any column" do
          expect(listed({slug: "anything"})).to contain_exactly(billing_draft, spanish_published, general)
        end
      end
    end
  end

  describe "GET #show" do
    let(:article) { create(:article) }

    subject { get :show, params: {id: article.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"
    end
  end

  describe "GET #new" do
    subject { get :new }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:create?, Support::Article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "defaults the article locale to the current locale" do
        subject
        expect(controller.instance_variable_get(:@article)).to have_attributes(locale: I18n.locale.to_s, title: nil)
      end
    end
  end

  describe "GET #edit" do
    let(:article) { create(:article) }

    subject { get :edit, params: {id: article.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it_behaves_like "respond to success"
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {support_article: {title: "Reset your password", summary: "How to reset it", body: "<p>Steps</p>", category: "account_access", locale: "en"}}
    end
    let(:invalid_params) { {support_article: {title: nil, summary: nil}} }

    subject { post :create, params: valid_params }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, Support::Article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it "creates a draft article" do
        expect { subject }.to change(Support::Article, :count).by(1)
        expect(Support::Article.last).to be_draft
      end

      it "sets the author to current_account" do
        subject
        expect(Support::Article.last.author).to eq(user)
      end

      it "generates the slug from the title" do
        subject
        expect(Support::Article.last.slug).to eq("reset-your-password")
      end

      it "redirects to the article" do
        expect(subject).to redirect_to(adminit_article_path(Support::Article.last))
      end

      context "with the general category" do
        it "creates a general article" do
          post :create, params: {support_article: valid_params[:support_article].merge(category: "general")}
          expect(Support::Article.last.category).to eq("general")
        end
      end

      context "with invalid params" do
        subject { post :create, params: invalid_params }

        it "does not create an article" do
          expect { subject }.not_to change(Support::Article, :count)
        end

        it "returns unprocessable entity" do
          expect(subject).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "PATCH #update" do
    let(:article) { create(:article, :published) }
    let(:params) { {id: article.id, support_article: {title: "Updated Title"}} }

    subject { patch :update, params: params }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it "updates the article" do
        expect { subject }.to change { article.reload.title }.to("Updated Title")
      end

      it "keeps the status and the author" do
        expect { subject }.not_to change { [article.reload.status, article.author_id] }
      end

      it "redirects to the article" do
        expect(subject).to redirect_to(adminit_article_path(article))
      end

      context "with invalid params" do
        let(:params) { {id: article.id, support_article: {summary: ""}} }

        it "does not update the article" do
          expect { subject }.not_to change { article.reload.summary }
        end

        it "returns unprocessable entity" do
          expect(subject).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:article) { create(:article) }

    subject { delete :destroy, params: {id: article.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it "destroys the article" do
        expect { subject }.to change(Support::Article, :count).by(-1)
      end

      it "redirects to index" do
        expect(subject).to redirect_to(adminit_articles_path)
      end

      context "when the article is published" do
        let!(:article) { create(:article, :published) }

        it "destroys the article" do
          expect { subject }.to change(Support::Article, :count).by(-1)
        end
      end
    end
  end

  describe "POST #publish" do
    let(:article) { create(:article) }

    subject { post :publish, params: {id: article.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it "publishes the article" do
        expect { subject }.to change { article.reload.status }.from("draft").to("published")
        expect(article.published_at).to be_present
      end

      it "redirects to the article with a notice" do
        expect(subject).to redirect_to(adminit_article_path(article))
        expect(flash[:notice]).to be_present
      end

      context "when already published" do
        let(:article) { create(:article, :published) }

        it "does not change the article" do
          expect { subject }.not_to change { article.reload.published_at }
        end

        it "shows an error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "POST #unpublish" do
    let(:article) { create(:article, :published) }

    subject { post :unpublish, params: {id: article.id} }

    include_context "adminit_auth"

    context "when logged with permission" do
      before do
        login_user(user)
        permitted
      end

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, article).with(Adminit::ArticlePolicy).with_context(user: user)
      end

      it "returns the article to draft" do
        expect { subject }.to change { article.reload.status }.from("published").to("draft")
      end

      it "redirects to the article with a notice" do
        expect(subject).to redirect_to(adminit_article_path(article))
        expect(flash[:notice]).to be_present
      end

      context "when still a draft" do
        let(:article) { create(:article) }

        it "does not change the status" do
          expect { subject }.not_to change { article.reload.status }
        end

        it "shows an error message" do
          subject
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "authorization" do
    context "when logged without the article permission" do
      before do
        login_user(user)
        app_permission
      end

      it "rejects index" do
        expect(get(:index)).to redirect_to(root_url)
      end

      it "does not create articles" do
        expect { post :create, params: {support_article: {title: "x", summary: "y", locale: "en"}} }.not_to change(Support::Article, :count)
      end
    end
  end
end
