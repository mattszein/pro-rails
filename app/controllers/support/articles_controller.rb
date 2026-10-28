module Support
  class ArticlesController < DashboardController
    before_action :require_account
    verify_authorized

    def index
      authorize! :article, with: Support::ArticlePolicy
      @query = params[:q].to_s.strip
      @category = selected_category
      @pagy, @articles = pagy(index_scope)
    end

    def show
      @article = find_published_article(params[:slug])
      authorize! @article
    end

    MIN_SUGGESTION_QUERY_LENGTH = 3
    SUGGESTIONS_LIMIT = 3

    # Lightweight "these might help" frame for the new-ticket form (deflection).
    def suggestions
      authorize! :article, with: Support::ArticlePolicy, to: :index?
      query = params[:q].to_s.strip
      @articles = if query.length < MIN_SUGGESTION_QUERY_LENGTH
        []
      else
        category = params[:category].to_s
        category = nil unless Support::Article.categories.key?(category)
        Support::Article.published_search(query, locale: I18n.locale, category: category, limit: SUGGESTIONS_LIMIT).to_a
      end
      render layout: false
    end

    private

    # Valid category key, or nil (all categories).
    def selected_category
      value = params[:category].to_s
      value if Support::Article.categories.key?(value)
    end

    def index_scope
      scope = if @query.present?
        Support::Article.published_search(@query, locale: I18n.locale, limit: nil)
      else
        Support::Article.published.where(locale: I18n.locale.to_s).order(published_at: :desc, id: :asc)
      end
      scope = scope.includes(:rich_text_body)
      @category ? scope.where(category: @category) : scope
    end

    # Current locale first, then the same slug in any other locale.
    def find_published_article(slug)
      published = Support::Article.published.where(slug: slug)
      published.find_by(locale: I18n.locale.to_s) || published.order(:id).first || raise(ActiveRecord::RecordNotFound)
    end
  end
end
