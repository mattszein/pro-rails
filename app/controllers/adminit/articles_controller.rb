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
  rescue Support::Article::InvalidTransition, ActiveRecord::RecordInvalid => e
    redirect_back_or_to adminit_article_path(@article), alert: e.message
  end

  def unpublish
    @article.unpublish!
    redirect_to adminit_article_path(@article), notice: t("adminit.articles.unpublished")
  rescue Support::Article::InvalidTransition, ActiveRecord::RecordInvalid => e
    redirect_back_or_to adminit_article_path(@article), alert: e.message
  end

  # Any status can be deleted: unlike announcements, nothing is sent or
  # scheduled from an article, and published articles must be removable.
  def destroy
    if @article.destroy
      redirect_to adminit_articles_path, notice: resource_message(:deleted, @article)
    else
      redirect_back_or_to adminit_articles_path, alert: @article.errors.full_messages.to_sentence
    end
  end

  private

  def set_article
    @article = Support::Article.find(params[:id])
    authorize! @article, with: Adminit::ArticlePolicy
  end

  def article_params
    params.require(:support_article).permit(:title, :slug, :summary, :body, :category, :locale)
  end

  # New/edit render in a modal frame: on success the frame redirects to show,
  # on failure the form is re-rendered in place.
  def respond_success(message, path)
    respond_to do |format|
      format.html { redirect_to path, notice: message }
      format.turbo_stream do
        flash[:notice] = message
        render turbo_stream: turbo_stream.action(:redirect, path)
      end
    end
  end

  def respond_form_error(action)
    respond_to do |format|
      format.html { render action, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "article_form",
          partial: "adminit/articles/form",
          locals: {article: @article}
        ), status: :unprocessable_content
      end
    end
  end
end
