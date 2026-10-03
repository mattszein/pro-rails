module Support
  class Article < ApplicationRecord
    class InvalidTransition < StandardError; end

    SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    self.table_name = "support_articles"

    belongs_to :author, class_name: "Account", optional: true
    has_rich_text :body

    enum :category, Support::Ticket::CATEGORIES, validate: {allow_nil: true}
    enum :status, {draft: 0, published: 1}, default: :draft, validate: {allow_nil: false}

    validates :title, :slug, :summary, :locale, presence: true
    validates :locale, inclusion: {in: ->(_) { I18n.available_locales.map(&:to_s) }}, allow_blank: true
    validates :slug, format: {with: SLUG_FORMAT}, allow_blank: true
    validates :slug, uniqueness: {scope: :locale}, allow_blank: true

    before_validation :normalize_slug
    before_save :sync_search_text

    scope :search_title, ->(query) { where("title ILIKE ?", "%#{sanitize_sql_like(query)}%") }

    # Full-text search over the generated `searchable` column. Chain `.published`
    # to restrict to published articles. With a category, general (nil) articles match too.
    def self.search(query, locale: nil, category: nil, limit: 5)
      return none if query.blank?

      tsquery = sanitize_sql_array(["websearch_to_tsquery('simple', ?)", query.to_s])
      scope = where("searchable @@ #{tsquery}")
      scope = scope.where(locale: locale.to_s) if locale.present?
      scope = scope.where(category: [categories.fetch(category.to_s), nil]) if category.present?
      scope.reorder(Arel.sql("ts_rank(searchable, #{tsquery}) DESC, published_at DESC NULLS LAST, id ASC")).limit(limit)
    end

    def breadcrumb_title = title

    def publish!
      raise InvalidTransition, I18n.t("article.transitions.already_published") if published?
      update!(status: :published, published_at: Time.current)
    end

    def unpublish!
      raise InvalidTransition, I18n.t("article.transitions.can_only_unpublish_published") unless published?
      update!(status: :draft)
    end

    private

    def normalize_slug
      self.slug = (slug.presence || title).to_s.parameterize.presence
    end

    def sync_search_text
      self.search_text = body.to_plain_text
    end
  end
end
