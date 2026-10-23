module SupportAi
  module Tools
    class SuggestArticles < ActionBase
      description "Attach help-center articles to your reply. Argument: article_ids, ids returned by search_articles."

      parameter :article_ids, type: :array, description: "Ids of articles found with search_articles"

      def execute(article_ids:)
        ids = Array(article_ids).filter_map { |id| Integer(id, exception: false) }
        valid = ids & Support::Article.published_among(ids).pluck(:id) # keeps the model's order
        collector.add_articles(valid)
        valid.any? ? "Attached #{valid.size} article(s)." : "No matching published articles; nothing attached."
      end
    end
  end
end
