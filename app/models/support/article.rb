module Support
  class Article < ApplicationRecord
    class InvalidTransition < StandardError; end

    SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    self.table_name = "support_articles"

    belongs_to :author, class_name: "Account", optional: true
    has_rich_text :body

    # Ticket categories plus `general`, for articles that fit no ticket category.
    GENERAL_CATEGORY = 100

    enum :category, Support::Ticket::CATEGORIES.merge(general: GENERAL_CATEGORY), default: :general, validate: {allow_nil: false}
    enum :status, {draft: 0, published: 1}, default: :draft, validate: {allow_nil: false}

    validates :title, :slug, :summary, :locale, presence: true
    validates :locale, inclusion: {in: ->(_) { I18n.available_locales.map(&:to_s) }}, allow_blank: true
    validates :slug, format: {with: SLUG_FORMAT}, allow_blank: true
    validates :slug, uniqueness: {scope: :locale}, allow_blank: true

    before_validation :normalize_slug
    before_save :sync_search_text

    scope :search_title, ->(query) { where("title ILIKE ?", "%#{sanitize_sql_like(query)}%") }

    # Published articles among `ids`; unknown or unpublished ids are dropped.
    scope :published_among, ->(ids) { published.where(id: ids) }

    # Help-center search: published articles only, in `locale`, ranked by relevance.
    def self.published_search(query, locale: nil, category: nil, limit: 5)
      search(query, locale: locale, category: category, limit: limit, published_only: true)
    end

    OR_TERM_FORMAT = /[[:alnum:]]{3,}/
    OR_TERM_LIMIT = 8
    # The OR pass needs a real hit, not just one stray body word. Measured ts_rank for a single
    # matching term: title ~0.30, summary ~0.12, body ~0.06. Several terms in the body (~0.18)
    # also pass, since that is a relevant article.
    OR_MIN_RANK = 0.1

    # Full-text search over the generated `searchable` column, ranked by ts_rank.
    #
    # Two passes: first `websearch_to_tsquery` (all words must match); when that matches no row,
    # an OR of prefix terms ("change password" -> `chang:* | password:*`), so a partial match still
    # finds something. Terms are strictly [[:alnum:]], so no tsquery syntax can be injected.
    #
    # The pass is decided with `exists?` on the AND query plus the locale/category filters (and any
    # scope the call is chained on, e.g. `Article.published.search`). A `.published` chained AFTER
    # `search` is not visible here, so a draft-only AND match would suppress the OR fallback for
    # published articles. Callers that restrict to published pass `published_only: true` (they may
    # still chain `.published`, which is then a no-op). With a category, general articles match too.
    def self.search(query, locale: nil, category: nil, limit: 5, published_only: false)
      return none if query.blank?

      base = all
      base = base.published if published_only
      base = base.where(locale: locale.to_s) if locale.present?
      base = base.where(category: [category.to_s, "general"]) if category.present?

      tsquery = sanitize_sql_array(["websearch_to_tsquery('simple', ?)", query.to_s])
      min_rank = nil
      unless base.where("searchable @@ #{tsquery}").exists?
        terms = query.to_s.downcase.scan(OR_TERM_FORMAT).uniq.first(OR_TERM_LIMIT)
        return none if terms.empty?

        tsquery = sanitize_sql_array(["to_tsquery('simple', ?)", terms.map { |term| "#{term}:*" }.join(" | ")])
        min_rank = OR_MIN_RANK
      end

      base = base.where("searchable @@ #{tsquery}")
      base = base.where("ts_rank(searchable, #{tsquery}) >= ?", min_rank) if min_rank
      base
        .reorder(Arel.sql("ts_rank(searchable, #{tsquery}) DESC, published_at DESC NULLS LAST, id ASC"))
        .limit(limit)
    end

    def breadcrumb_title = title

    # Plain-text body, squished and truncated (with an ellipsis) for prompts.
    def excerpt(length = 1_200) = search_text.to_s.squish.truncate(length)

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
