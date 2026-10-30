class Adminit::ArticlesController < Adminit::ApplicationController
  include Tableable

  before_action :set_article, only: %i[show edit update destroy publish unpublish]
  verify_authorized

  def index
    authorize! Support::Article, with: Adminit::ArticlePolicy
    @columns = helpers.article_columns
    @pagy, @articles = apply_table_params(
      Support::Article.includes(:author).order(created_at: :desc),
      columns: @columns
    )
  end

  def show
  end

  def new
    authorize! Support::Article, with: Adminit::ArticlePolicy
    @article = Support::Article.new(locale: I18n.locale.to_s)
  end

  def edit
  end

  def create
    authorize! Support::Article, with: Adminit::ArticlePolicy
    @article = Support::Article.new(article_params)
    @article.author = current_account
    if @article.save
      respond_success(resource_message(:created, @article), adminit_article_path(@article))
    else
      respond_form_error(:new)
    end
  end

  def update
    if @article.update(article_params)
      respond_success(resource_message(:updated, @article), adminit_article_path(@article))
    else
      respond_form_error(:edit)
    end
  end

  def publish
    @article.publish!
    redirect_to adminit_article_path(@article), notice: t("adminit.articles.published")
  end

  def unpublish
    @article.unpublish!
    redirect_to adminit_article_path(@article), notice: t("adminit.articles.unpublished")
  end

  # Unlike announcements, any status can be deleted.
  def destroy
    if @article.destroy
      redirect_to adminit_articles_path, notice: resource_message(:deleted, @article)
    else
      redirect_back_or_to adminit_articles_path, alert: @article.errors.full_messages.to_sentence
    end
  end

  private

  def transition_error_path
    @article ? adminit_article_path(@article) : adminit_articles_path
  end

  def set_article
    @article = Support::Article.find(params[:id])
    authorize! @article, with: Adminit::ArticlePolicy
  end

  def article_params
    params.require(:support_article).permit(:title, :slug, :summary, :body, :category, :locale)
  end

  def modal_form_locals
    {article: @article}
  end
end
