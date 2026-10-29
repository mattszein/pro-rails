module SupportAi
  # Runs one LLM step for a ticket. Pure: takes records, calls the model, returns a
  # Llm::Result. Never writes to the database; interactors persist (and log AiRuns).
  #
  # The LLM plumbing (chat, timeout, tokens, tool budget) lives in Llm::Runner; this class keeps
  # the support logic: prompts, parsing, validation, KB gap.
  #
  # Steps (each returns a Result; `output` documented per method): triage, handle, respond (follow-ups).
  # A future `draft` step needs only a Prompts function, a registry entry and one public method calling `run_step`.
  class Responder
    TRIAGE_SCHEMA = {
      name: "support_triage",
      strict: true,
      schema: {
        type: "object",
        additionalProperties: false,
        properties: {
          category: {type: "string", enum: Support::Ticket::CATEGORIES.keys.map(&:to_s)},
          priority: {type: "integer", minimum: 1, maximum: 5},
          sentiment: {type: "string", enum: %w[negative neutral positive]},
          language: {type: "string"},
          summary: {type: "string"},
          escalate: {type: "boolean"},
          escalate_reason: {type: "string"}
        },
        required: %w[category priority sentiment language summary escalate escalate_reason]
      }
    }.freeze

    SENTIMENTS = %w[negative neutral positive].freeze
    MAX_IMAGES = 3
    MAX_KB_QUERIES = 3
    MAX_ARTICLES = 3
    KB_GAP_HANDOFF_REASON = "No help-center article matched (KB gap)"

    attr_reader :ticket, :playbook

    # `playbook` may be nil only for #triage (it runs before a playbook is selected).
    def initialize(ticket:, playbook: nil)
      @ticket = ticket
      @playbook = playbook
    end

    # Result#output: {category: "billing", priority: 1..5, sentiment: "negative|neutral|positive",
    # language: "en|es|other", summary: String, escalate: true/false, escalate_reason: String}.
    # No tools. Raises Llm::Error on invalid category/priority/sentiment/booleans.
    def triage
      prompt = Prompts.triage(ticket: ticket)
      run_step(model: SupportAiConfig.model, system: prompt.system, schema: TRIAGE_SCHEMA) do |chat|
        parse_triage(chat.ask(prompt.user))
      end
    end

    # The main step: ONE chat and ONE tool budget, two turns.
    #   Turn 1: internal note for the ADMIN (plain text) from the ticket, triage and the Context
    #           blocks (account facts, past tickets, prefetched articles); vision when enabled.
    #   Turn 2 (only when `reply`): the reply as a JSON object (see #ask_for_answer), same chat so
    #           anything search_articles returned stays in context.
    #
    # Result#output: {findings: String (non-empty), reply: String or nil (nil when reply: false),
    # article_ids:, resolution_proposed:, handoff_requested:, handoff_reason:,
    # kb_gap: Boolean, kb_queries: [String] (max 3)}.
    #
    # KB gap (code-enforced): the playbook can search_articles but neither the prefetch nor any
    # search the model ran returned an article. The reply request then forbids describing the
    # interface and the handoff is forced (the model's own handoff reason wins). Computed for
    # reply: false too. Playbooks without search_articles never have a gap.
    def handle(triage: nil, reply: true, trigger_message: nil)
      @search_locale = locale_from(triage)
      budget = ToolBudget.new
      context = Context.new(ticket: ticket, playbook: playbook, budget: budget, locale: search_locale, query_texts: [ticket.title, ticket.description])
      prompt = Prompts.handle(ticket: ticket, playbook: playbook, triage: triage, context: context.to_prompt)
      images = vision_images
      model = images.any? ? SupportAiConfig.vision_model : SupportAiConfig.model

      run_step(model: model, system: prompt.system, tools: tools_for(:handle, budget), budget: budget) do |chat|
        conversation_turns(trigger_message).each { |turn| chat.add_message(turn) }

        findings = (images.any? ? chat.ask(prompt.user, with: images) : chat.ask(prompt.user)).content.to_s.strip
        raise Llm::Error, "The model returned no findings" if findings.empty?

        kb_gap = playbook.capability?(:search_articles) && !budget.articles_found?
        answer = reply ? ask_for_answer(chat, Prompts.reply_request(kb_gap: kb_gap), budget) : nil
        answer = force_kb_gap_handoff(answer) if kb_gap && answer

        answer_output(answer).merge(findings: findings, kb_gap: kb_gap, kb_queries: budget.searched_queries.first(MAX_KB_QUERIES))
      end
    end

    # Follow-up turns. Result#output: {reply: String (non-empty), article_ids: [Integer] (seen and
    # published, max 3), resolution_proposed:, handoff_requested:, handoff_reason:}.
    # The user's last message is sent as the final prompt (with the JSON format request); earlier
    # history is replayed (human requester -> user, ai -> assistant, other senders skipped).
    # Triage and the first-pass note come from the ticket's earlier succeeded runs. Vision is
    # not attached here (handle only).
    def respond(trigger_message: nil)
      history = conversation_turns(trigger_message)
      triage = ticket.ai_runs.latest_output(:triage)
      @search_locale = locale_from(triage)
      budget = ToolBudget.new
      context = Context.new(ticket: ticket, playbook: playbook, budget: budget, locale: search_locale,
        query_texts: [latest_requester_text(trigger_message), ticket.title])
      prompt = Prompts.respond(
        ticket: ticket, playbook: playbook, ai_replies_so_far: history.count { |turn| turn[:role] == :assistant },
        triage: triage, findings: ticket.ai_runs.latest_output(:handle)&.dig(:findings), context: context.to_prompt
      )

      run_step(model: SupportAiConfig.model, system: prompt.system, tools: tools_for(:respond, budget), budget: budget) do |chat|
        turns = [{role: :user, content: prompt.user}] + history
        turns << {role: :user, content: "Please continue helping with this ticket."} if turns.last[:role] == :assistant
        final = turns.pop
        turns.each { |turn| chat.add_message(turn) }

        answer_output(ask_for_answer(chat, "#{final[:content]}\n\n#{Prompts::REPLY_FORMAT}", budget))
      end
    end

    private

    # Runs the block through the shared Llm::Runner (chat setup, timeout, tokens, tool budget
    # backstop, transcript capture). Any Llm::Error leaves with the transcript and tool calls attached.
    def run_step(model:, system:, tools: [], schema: nil, budget: ToolBudget.new, &block)
      runner.call(model: model, system: system, tools: tools, schema: schema, budget: budget, &block)
    end

    def runner
      @runner ||= Llm::Runner.new(timeout: SupportAiConfig.timeout, temperature: SupportAiConfig.temperature)
    end

    # Triage language when it is a supported locale, else the request locale.
    def locale_from(triage)
      language = triage.to_h.with_indifferent_access[:language].to_s
      %w[en es].include?(language) ? language : nil
    end

    def search_locale = @search_locale || I18n.locale.to_s

    def latest_requester_text(trigger_message)
      messages = all_messages
      messages += [trigger_message] if trigger_message && messages.none? { |message| message.id == trigger_message.id }
      messages.reverse.find { |message| !message.ai? && message.account_id == ticket.created_id }&.content.to_s
    end

    # Tool instances for the tool capabilities the playbook enabled in `step` (the registry is the
    # only gate). Tools only read this user's data or the public help center.
    def tools_for(step, budget)
      Support::AiCapabilities.for_step(step, playbook&.capabilities).select(&:tool?).filter_map do |capability|
        capability.tool_class&.constantize&.new(ticket: ticket, budget: budget, locale: search_locale)
      end
    end

    # Asks for the answer JSON {reply, article_ids, resolution_proposed, handoff, handoff_reason}
    # as plain text (the spike showed text JSON is as reliable as response schemas next to tools
    # on the configured model, and works on any provider). One retry on invalid JSON or an empty
    # reply, then Llm::Error. Returns the validated answer Hash.
    def ask_for_answer(chat, request, budget)
      parse_answer(chat.ask(request), budget) ||
        parse_answer(chat.ask(Prompts::RETRY_REQUEST), budget) ||
        raise(Llm::Error, "The model returned no valid reply")
    end

    def parse_answer(message, budget)
      data = parse_json(message)
      reply = data["reply"].to_s.strip
      return if reply.empty?

      {
        reply: reply,
        article_ids: valid_article_ids(data["article_ids"], budget),
        resolution_proposed: truthy?(data["resolution_proposed"]),
        handoff: truthy?(data["handoff"]),
        handoff_reason: data["handoff_reason"].to_s.strip.truncate(500)
      }
    rescue Llm::Error, JSON::ParserError
      nil
    end

    # Only ids the model actually saw (prefetched or returned by search_articles in this step),
    # still published, in the model's order, at most MAX_ARTICLES.
    def valid_article_ids(raw, budget)
      ids = Array(raw).filter_map { |id| Integer(id, exception: false) } & budget.found_article_ids
      (ids & Support::Article.published_among(ids).pluck(:id)).first(MAX_ARTICLES)
    end

    def truthy?(value) = value == true || %w[true yes 1].include?(value.to_s.strip.downcase)

    def force_kb_gap_handoff(answer)
      return answer if answer[:handoff]

      answer.merge(handoff: true, handoff_reason: KB_GAP_HANDOFF_REASON)
    end

    def answer_output(answer)
      {
        reply: answer&.fetch(:reply),
        article_ids: answer&.fetch(:article_ids) || [],
        resolution_proposed: answer&.fetch(:resolution_proposed) || false,
        handoff_requested: answer&.fetch(:handoff) || false,
        handoff_reason: answer&.fetch(:handoff_reason) || ""
      }
    end

    def vision_images
      return [] unless playbook&.capability?(:vision_attachments)

      ticket.attachments.select { |attachment| attachment.blob.content_type.to_s.start_with?("image/") }.first(MAX_IMAGES)
    end

    def all_messages
      ticket.conversation ? ticket.conversation.messages.chronological.last(SupportAiConfig.history_limit) : []
    end

    def conversation_turns(trigger_message)
      messages = all_messages
      messages += [trigger_message] if trigger_message && messages.none? { |message| message.id == trigger_message.id }

      messages.filter_map do |message|
        if message.ai?
          {role: :assistant, content: message.content}
        elsif message.account_id == ticket.created_id
          {role: :user, content: Prompts.untrusted("user message", message.content)}
        end
      end
    end

    def parse_triage(message)
      data = parse_json(message)
      category = data["category"].to_s
      raise Llm::Error, "Invalid triage category: #{category.inspect}" unless Support::Ticket::CATEGORIES.key?(category.to_sym)

      priority = Integer(data["priority"], exception: false)
      raise Llm::Error, "Invalid triage priority: #{data["priority"].inspect}" unless priority && (1..5).cover?(priority)

      sentiment = data["sentiment"].to_s
      raise Llm::Error, "Invalid triage sentiment: #{sentiment.inspect}" unless SENTIMENTS.include?(sentiment)

      escalate = data["escalate"]
      raise Llm::Error, "Invalid triage escalate flag: #{escalate.inspect}" unless [true, false].include?(escalate)

      {
        category: category,
        priority: priority,
        sentiment: sentiment,
        language: data["language"].to_s.strip.downcase.presence || "other",
        summary: data["summary"].to_s.strip,
        escalate: escalate,
        escalate_reason: data["escalate_reason"].to_s.strip
      }
    end

    # Tolerant: models sometimes wrap JSON in ``` fences or add a sentence around it.
    def parse_json(message)
      return message.content.deep_stringify_keys if message.content.is_a?(Hash)

      raw = message.content.to_s.strip.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
      data = begin
        JSON.parse(raw)
      rescue JSON::ParserError
        embedded = raw[/\{.*\}/m]
        raise unless embedded

        JSON.parse(embedded)
      end
      raise Llm::Error, "Structured output was not a JSON object" unless data.is_a?(Hash)
      data
    end
  end
end
