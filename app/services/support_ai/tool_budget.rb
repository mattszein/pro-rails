module SupportAi
  # Per-step tool-call budget shared by every tool of one Responder step.
  #
  # - `record` logs every call the model attempts (name + arguments), for the audit row.
  # - Executed calls count against `limit`; an IDENTICAL call (same tool and arguments) is served
  #   from the cache and costs nothing.
  # - Once `exhausted?`, tools refuse to run and answer with LIMIT_MESSAGE so the model writes its
  #   final answer. If it keeps calling anyway (BACKSTOP more attempts), `backstop_hit?` turns true
  #   and the Responder aborts the step with SupportAi::Error.
  class ToolBudget
    BACKSTOP = 3
    LIMIT_MESSAGE = "Tool limit reached. Answer now using what you already know."

    attr_reader :limit, :calls, :searched_queries, :found_article_ids

    def initialize(limit: SupportAiConfig.max_tool_calls)
      @limit = limit
      @calls = []
      @cache = {}
      @executed = 0
      @refused = 0
      @searched_queries = []
      @found_article_ids = []
    end

    def record(name, arguments)
      @calls << {name: name.to_s, arguments: arguments}
    end

    # Recorded by the search tool. Idempotent: repeated queries and ids are kept once, in order.
    def note_search(query:, article_ids:)
      @searched_queries |= [query.to_s]
      @found_article_ids |= Array(article_ids)
    end

    def articles_found? = found_article_ids.any?

    def exhausted? = @executed >= limit

    def backstop_hit? = @refused >= BACKSTOP

    # The tool's result for this call: cached, a limit error, or whatever the block returns.
    def run(name, arguments)
      key = cache_key(name, arguments)
      return @cache[key] if @cache.key?(key)

      if exhausted?
        @refused += 1
        return {error: LIMIT_MESSAGE}
      end

      @executed += 1
      @cache[key] = yield
    end

    private

    def cache_key(name, arguments)
      [name.to_s, arguments.to_h.deep_stringify_keys.sort.to_h].to_json
    end
  end
end
