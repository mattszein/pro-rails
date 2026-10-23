module SupportAi
  module Tools
    class SearchArticles < Base
      LIMIT = 3

      description "Search the published help-center articles. Argument: query. Returns up to 3 articles " \
        "with id, title, summary, slug and locale."

      parameter :query, description: "What the user needs help with"

      def initialize(ticket:, budget: nil, locale: nil, **)
        super(ticket: ticket, budget: budget)
        @locale = locale.presence || I18n.locale.to_s
      end

      # The user's language first, then any language. No category filter: the ticket category is
      # an AI classification that can be wrong.
      def execute(query:)
        found = search(query, locale: locale)
        found = search(query) if found.empty?
        budget&.note_search(query: query, article_ids: found.map(&:id))
        {articles: found.map { |article| present(article) }}
      end

      private

      attr_reader :locale

      def search(query, locale: nil)
        Support::Article.search(query, locale: locale, limit: LIMIT, published_only: true).published.to_a
      end

      def present(article)
        {id: article.id, title: article.title, summary: article.summary.to_s.truncate(200), slug: article.slug, locale: article.locale}
      end
    end
  end
end
