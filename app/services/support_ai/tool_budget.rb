module SupportAi
  # Llm::ToolBudget for one Responder step, plus knowledge-base tracking: which queries were
  # searched and which article ids the model saw (prefetch and search_articles). The Responder
  # uses it for the KB-gap rule and to validate cited article ids.
  class ToolBudget < Llm::ToolBudget
    attr_reader :searched_queries, :found_article_ids

    def initialize(limit: SupportAiConfig.max_tool_calls)
      super
      @searched_queries = []
      @found_article_ids = []
    end

    # Recorded by the search tool. Idempotent: repeated queries and ids are kept once, in order.
    def note_search(query:, article_ids:)
      @searched_queries |= [query.to_s]
      @found_article_ids |= Array(article_ids)
    end

    def articles_found? = found_article_ids.any?
  end
end
