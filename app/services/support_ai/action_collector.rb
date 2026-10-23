module SupportAi
  # Per-call sink for ACTION tools. Tools never touch the database; they record intent
  # here and the interactor (phase D) persists it from Result#output.
  class ActionCollector
    MAX_ARTICLES = 3

    attr_reader :handoff, :handoff_reason, :resolution_proposed, :article_ids

    def initialize
      @handoff = false
      @handoff_reason = ""
      @resolution_proposed = false
      @article_ids = []
    end

    alias_method :handoff?, :handoff
    alias_method :resolution_proposed?, :resolution_proposed

    def request_handoff(reason)
      @handoff = true
      @handoff_reason = reason.to_s
    end

    # Code-enforced handoff (e.g. KB gap). Keeps the model's own reason if it already asked.
    def force_handoff(reason)
      request_handoff(reason) unless @handoff
    end

    def propose_resolution
      @resolution_proposed = true
    end

    def add_articles(ids)
      @article_ids = (@article_ids + Array(ids)).uniq.first(MAX_ARTICLES)
    end
  end
end
