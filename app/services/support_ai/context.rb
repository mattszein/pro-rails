module SupportAi
  # Deterministic context the code puts into the first prompt, so the model does not need a tool
  # call for it. One block per context capability the playbook enabled:
  #   account_facts - the requester's own status, verification, member-since date and role (no email)
  #   past_tickets  - the requester's own previous tickets (up to 10)
  #   search_articles - retrieval-first help-center search with the ticket text (recorded on the budget)
  # Every block is wrapped as untrusted. Never reads other users' data (similar tickets are an
  # admin-only note line, see Support::Ai::Handle).
  class Context
    PAST_TICKETS_LIMIT = 10
    ARTICLES_LIMIT = 3
    ARTICLE_QUERY_LENGTH = 300

    # `query_texts`: strings searched in the help center (words only, ~300 chars).
    def initialize(ticket:, playbook:, budget:, locale: nil, query_texts: [])
      @ticket = ticket
      @playbook = playbook
      @budget = budget
      @locale = locale.presence || I18n.locale.to_s
      @query_texts = query_texts
    end

    # The text for the prompt (blank blocks dropped).
    def to_prompt
      [account_facts_block, past_tickets_block, articles_block].compact_blank.join("\n\n")
    end

    # nil when the playbook cannot search; else the matching published articles (possibly empty).
    def articles
      return @articles if defined?(@articles)

      @articles = playbook.capability?(:search_articles) ? prefetch_articles : nil
    end

    def account_facts
      account = ticket.created
      return unless account

      {status: account.status, verified: account.verified?, member_since: account.created_at.to_date.iso8601, role: account.role&.name}
    end

    def past_tickets
      Support::Ticket.history_for(ticket, limit: PAST_TICKETS_LIMIT).map do |past|
        {id: past.id, title: past.title.to_s.truncate(120), category: past.category, status: past.status,
         created_on: past.created_at.to_date.iso8601, finished: past.finished?}
      end
    end

    private

    attr_reader :ticket, :playbook, :budget, :locale, :query_texts

    def account_facts_block
      return unless playbook.capability?(:account_facts)

      facts = account_facts
      return unless facts

      Prompts.untrusted("requester account facts", facts.map { |key, value| "#{key}: #{value.nil? ? "none" : value}" }.join("\n"))
    end

    def past_tickets_block
      return unless playbook.capability?(:past_tickets)

      lines = past_tickets.map { |past| "##{past[:id]} #{past[:title]} (#{past[:category]}, #{past[:status]}, #{past[:created_on]})" }
      Prompts.untrusted("requester past tickets", lines.presence&.join("\n") || "none")
    end

    # nil = playbook cannot search (no block); [] = nothing matched.
    def articles_block
      found = articles
      return if found.nil?

      if found.empty?
        return "Help-center search (automatic): no published article matched this ticket. You may try one or two refined search_articles queries before concluding there is no guide."
      end

      lines = ["Help-center articles that may answer this ticket (found automatically; cite the ones you use in article_ids):"]
      found.each do |article|
        lines << "Article id #{article.id} (slug: #{article.slug}, locale: #{article.locale})"
        lines << Prompts.untrusted("help-center article", "Title: #{article.title}\nSummary: #{article.summary}\nExcerpt: #{article.excerpt}")
      end
      lines.join("\n")
    end

    def prefetch_articles
      query = query_texts.join(" ").scan(/[[:alnum:]]+/).join(" ").truncate(ARTICLE_QUERY_LENGTH, omission: "").strip
      return [] if query.blank?

      found = search(query, locale)
      found = search(query, nil) if found.empty?
      budget.note_search(query: query, article_ids: found.map(&:id))
      found
    end

    def search(query, locale)
      Support::Article.published_search(query, locale: locale, limit: ARTICLES_LIMIT).to_a
    end
  end
end
