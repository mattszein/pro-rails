module SupportAi
  # Runs one LLM step for a ticket. Pure: takes records, calls the model, returns a
  # SupportAi::Result. Never writes to the database; interactors persist (and log AiRuns).
  #
  # RubyLLM usage mirrors AvatarAi::BaseGenerator: OpenRouter ids, registry lookup skipped.
  #
  # Steps (each returns a Result; `output` documented per method):
  #   triage, handle, investigate (optional admin-only similar cases), respond (follow-ups), summarize. A future `draft` step needs only a new
  #   Prompts class, a `tools_for(:draft)` entry in the registry and one public method calling `run_step`.
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
    PROVIDER = :openrouter
    MAX_KB_QUERIES = 3
    KB_GAP_HANDOFF_REASON = "No help-center article matched (KB gap)"
    PREFETCH_LIMIT = 3
    PREFETCH_QUERY_LENGTH = 300

    attr_reader :ticket, :playbook

    # `playbook` may be nil only for #triage (it runs before a playbook is selected).
    def initialize(ticket:, playbook: nil)
      @ticket = ticket
      @playbook = playbook
    end

    # Result#output: {category: "billing", priority: 1..5, sentiment: "negative|neutral|positive",
    # language: "en|es|other", summary: String, escalate: true/false, escalate_reason: String}.
    # No tools. Raises SupportAi::Error on invalid category/priority/sentiment/booleans.
    def triage
      prompt = Prompts::Triage.new(ticket: ticket)
      run_step(model: SupportAiConfig.model, prompt: prompt, schema: TRIAGE_SCHEMA) do |chat|
        parse_triage(chat.ask(prompt.user))
      end
    end

    # The main step: ONE chat and ONE tool budget, two turns.
    #   Turn 1: investigate (respond-safe tools, vision when enabled) -> internal findings and a
    #           recommended next step for the ADMIN (plain text).
    #   Turn 2 (only when `reply`): "now write the reply to the user", same chat so the tool
    #           results stay in context. May call suggest_articles/propose_resolution/request_human.
    #
    # Result#output: {findings: String (non-empty), reply: String or nil (nil when reply: false),
    # article_ids:, resolution_proposed:, handoff_requested:, handoff_reason:,
    # kb_gap: Boolean, kb_queries: [String] (max 3)}.
    #
    # Retrieval-first: before turn 1 the code searches the help center with the ticket text and puts
    # the top matches (title, summary, body excerpt) into the turn-1 prompt. The search is recorded
    # on the budget, so kb_queries shows it and it counts for the gap. Prompt only, no DB write.
    #
    # KB gap (code-enforced): the playbook can search_articles but neither the automatic search nor
    # any search the model ran in turn 1 returned an article. The reply request then forbids describing the interface and the handoff is forced
    # (the model's own request_human reason wins). Computed for reply: false too. Playbooks
    # without search_articles never have a gap.
    #
    # Tools are the :respond step set only (account_facts, past_tickets, search_articles + actions):
    # similar_tickets (other users' data) is declared for :investigate only and can never appear
    # here, because this chat's output feeds user-facing prompts. request_human is always available.
    # Empty findings raise; an empty reply is retried once, then raises (flags come from the
    # ActionCollector since structured schemas are unreliable together with tools on free models).
    def handle(triage: nil, reply: true, trigger_message: nil)
      @search_locale = locale_from(triage)
      collector = ActionCollector.new
      budget = ToolBudget.new
      articles = prefetch_articles([ticket.title, ticket.description], budget)
      prompt = Prompts::Handle.new(ticket: ticket, playbook: playbook, triage: triage, articles: articles)
      images = vision_images
      model = images.any? ? SupportAiConfig.vision_model : SupportAiConfig.model
      tools = respond_tools(collector: collector, budget: budget)

      run_step(model: model, prompt: prompt, tools: tools, budget: budget) do |chat|
        conversation_turns(trigger_message).each { |turn| chat.add_message(turn) }

        findings = (images.any? ? chat.ask(prompt.user, with: images) : chat.ask(prompt.user)).content.to_s.strip
        raise Error, "The model returned no findings" if findings.empty?

        kb_gap = playbook.capability?(:search_articles) && !budget.articles_found?
        reply_text = reply ? ask_for_reply(chat, prompt.reply_request(kb_gap: kb_gap)) : nil
        collector.force_handoff(KB_GAP_HANDOFF_REASON) if kb_gap && reply

        {
          findings: findings,
          reply: reply_text,
          article_ids: collector.article_ids,
          resolution_proposed: collector.resolution_proposed,
          handoff_requested: collector.handoff,
          handoff_reason: collector.handoff_reason,
          kb_gap: kb_gap,
          kb_queries: budget.searched_queries.first(MAX_KB_QUERIES)
        }
      end
    end

    # Optional ADMIN-ONLY supplement: similar past cases (similar_tickets reads other requesters'
    # tickets). Result#output: String note. Its output never feeds a user-facing prompt.
    def investigate
      prompt = Prompts::Investigate.new(ticket: ticket, playbook: playbook)
      budget = ToolBudget.new
      run_step(model: SupportAiConfig.model, prompt: prompt, tools: tools_for(:investigate, budget: budget), budget: budget) do |chat|
        text = chat.ask(prompt.user).content.to_s.strip
        raise Error, "Investigation returned an empty note" if text.empty?
        text
      end
    end

    # Result#output: {reply: String (non-empty), article_ids: [Integer] (published only, max 3),
    # resolution_proposed: Boolean, handoff_requested: Boolean, handoff_reason: String}.
    #
    # Reply = the final assistant text. Structured schemas are unreliable together with tools on
    # free models, so flags come from the ActionCollector the action tools write to. If the model
    # ends a turn with no text (tool calls only) we ask once more for the reply; if still empty
    # we raise SupportAi::Error. The user's last message is sent as the final prompt; earlier
    # history is replayed (human requester -> user, ai -> assistant, other senders skipped).
    # Vision is not attached here (handle only). Triage result and the handle findings come from
    # the ticket's earlier succeeded runs (see Prompts::Respond).
    def respond(trigger_message: nil)
      history = conversation_turns(trigger_message)
      triage = ticket.ai_runs.latest_output(:triage)
      @search_locale = locale_from(triage)
      collector = ActionCollector.new
      budget = ToolBudget.new
      articles = prefetch_articles([latest_requester_text(trigger_message), ticket.title], budget)
      prompt = Prompts::Respond.new(
        ticket: ticket, playbook: playbook, ai_replies_so_far: history.count { |turn| turn[:role] == :assistant },
        triage: triage, findings: ticket.ai_runs.latest_output(:handle)&.dig(:findings), articles: articles
      )
      tools = respond_tools(collector: collector, budget: budget)

      run_step(model: SupportAiConfig.model, prompt: prompt, tools: tools, budget: budget) do |chat|
        turns = [{role: :user, content: prompt.user}] + history
        turns << {role: :user, content: "Please continue helping with this ticket."} if turns.last[:role] == :assistant
        final = turns.pop
        turns.each { |turn| chat.add_message(turn) }

        message = chat.ask(final[:content])
        reply = message.content.to_s.strip
        reply = ask_for_reply(chat, nil) if reply.empty?

        {
          reply: reply,
          article_ids: collector.article_ids,
          resolution_proposed: collector.resolution_proposed,
          handoff_requested: collector.handoff,
          handoff_reason: collector.handoff_reason
        }
      end
    end

    # Result#output: String handoff summary for admins. No tools.
    def summarize
      transcript = all_messages.map { |message| [speaker_for(message), message.content] }
      prompt = Prompts::Summary.new(ticket: ticket, playbook: playbook, transcript: transcript)

      run_step(model: SupportAiConfig.model, prompt: prompt) do |chat|
        text = chat.ask(prompt.user).content.to_s.strip
        raise Error, "Summary was empty" if text.empty?
        text
      end
    end

    private

    # Builds the chat, runs the block (which performs the asks), and wraps the output in a Result.
    # On ANY SupportAi::Error (raised, backstop, or wrapped provider/timeout error) the chat's
    # transcript and the budget's recorded tool calls are attached to the error before re-raising.
    def run_step(model:, prompt:, tools: [], schema: nil, budget: ToolBudget.new)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      chat = nil
      chat = build_chat(model, prompt.system, tools, schema, budget)

      output = Timeout.timeout(SupportAiConfig.timeout) { yield chat }

      usage = chat.tokens
      Result.new(
        output: output,
        model: model,
        input_tokens: usage.input.to_i,
        output_tokens: usage.output.to_i,
        latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
        tool_calls: budget.calls,
        transcript: Transcript.build(chat.messages)
      )
    rescue Error => e
      raise capture(e, chat, budget)
    rescue RubyLLM::Error, RubyLLM::ConfigurationError, RubyLLM::ModelNotFoundError, Timeout::Error, JSON::ParserError => e
      raise capture(Error.new("#{e.class.name.demodulize}: #{e.message}"), chat, budget)
    end

    def capture(error, chat, budget)
      error.transcript = chat ? Transcript.build(chat.messages) : []
      error.tool_calls = budget.calls
      error
    end

    def build_chat(model, instructions, tools, schema, budget)
      chat = RubyLLM.chat(model: model, provider: PROVIDER, assume_model_exists: true)
        .with_instructions(instructions)
        .with_temperature(SupportAiConfig.temperature)
      chat.with_tools(*tools) if tools.any?
      chat.with_schema(schema) if schema
      # Records every attempted call; tools answer with a limit message once the budget is spent
      # (see Tools::Base#call). This only aborts if the model ignores that and keeps calling.
      chat.before_tool_call do |tool_call|
        raise Error, "Too many tool calls (limit #{budget.limit})" if budget.backstop_hit?

        budget.record(tool_call.name, tool_call.arguments)
      end
      chat
    end

    # Tool instances allowed by the registry for `step` and the playbook. Registry.for_step is
    # the only gate: similar_tickets is declared for :investigate only, so it can never appear
    # in :respond. Investigate gets read tools only.
    # Triage language when it is a supported locale, else the request locale.
    def locale_from(triage)
      language = triage.to_h.with_indifferent_access[:language].to_s
      %w[en es].include?(language) ? language : nil
    end

    # Searches the help center with `texts` (words only, ~300 chars) and records it on the budget.
    # Returns nil when the playbook cannot search (no block in the prompt), else the matching
    # published articles (possibly empty). A blank query is treated as no match and not recorded.
    def prefetch_articles(texts, budget)
      return nil unless playbook&.capability?(:search_articles)

      query = texts.join(" ").scan(/[[:alnum:]]+/).join(" ").truncate(PREFETCH_QUERY_LENGTH, omission: "").strip
      return [] if query.blank?

      articles = search_published(query, search_locale)
      articles = search_published(query, nil) if articles.empty?
      budget.note_search(query: query, article_ids: articles.map(&:id))
      articles
    end

    def search_published(query, locale)
      Support::Article.search(query, locale: locale, limit: PREFETCH_LIMIT, published_only: true).published.to_a
    end

    def latest_requester_text(trigger_message)
      messages = all_messages
      messages += [trigger_message] if trigger_message && messages.none? { |message| message.id == trigger_message.id }
      messages.reverse.find { |message| !message.ai? && message.account_id == ticket.created_id }&.content.to_s
    end

    def search_locale = @search_locale || I18n.locale.to_s

    def tools_for(step, collector: nil, budget: nil)
      SupportAi::Capabilities::Registry.for_step(step, playbook&.capabilities).filter_map do |capability|
        next if capability.tool_class.blank?
        next if step == :investigate && !capability.read?

        klass = capability.tool_class.constantize
        klass.action? ? klass.new(ticket: ticket, collector: collector, budget: budget) : klass.new(ticket: ticket, budget: budget, locale: search_locale)
      end
    end

    # request_human is ALWAYS available, even if the playbook did not list it.
    def respond_tools(collector:, budget:)
      tools = tools_for(:respond, collector: collector, budget: budget)
      tools << Tools::RequestHuman.new(ticket: ticket, collector: collector, budget: budget) unless tools.any?(Tools::RequestHuman)
      tools
    end

    # Asks for the user-facing reply (`request` nil = only the "write it as text" nudge, used by
    # #respond after the reply turn came back empty). Retries once if the model returns no text.
    def ask_for_reply(chat, request)
      text = request ? chat.ask(request).content.to_s.strip : ""
      text = chat.ask("Now write your reply to the user, as plain text.").content.to_s.strip if text.empty?
      raise Error, "The model returned no reply text" if text.empty?
      text
    end

    def vision_images
      return [] unless playbook&.capabilities&.include?("vision_attachments")

      ticket.attachments.select { |attachment| attachment.blob.content_type.to_s.start_with?("image/") }.first(MAX_IMAGES)
    end

    def all_messages
      ticket.conversation ? ticket.conversation.messages.chronological.last(SupportAiConfig.history_limit) : []
    end

    def speaker_for(message)
      return "assistant" if message.ai?

      (message.account_id == ticket.created_id) ? "user" : "admin"
    end

    def conversation_turns(trigger_message)
      messages = all_messages
      messages += [trigger_message] if trigger_message && messages.none? { |message| message.id == trigger_message.id }

      messages.filter_map do |message|
        if message.ai?
          {role: :assistant, content: message.content}
        elsif message.account_id == ticket.created_id
          {role: :user, content: Prompts::Base.untrusted("user message", message.content)}
        end
      end
    end

    def parse_triage(message)
      data = parse_json(message)
      category = data["category"].to_s
      raise Error, "Invalid triage category: #{category.inspect}" unless Support::Ticket::CATEGORIES.key?(category.to_sym)

      priority = Integer(data["priority"], exception: false)
      raise Error, "Invalid triage priority: #{data["priority"].inspect}" unless priority && (1..5).cover?(priority)

      sentiment = data["sentiment"].to_s
      raise Error, "Invalid triage sentiment: #{sentiment.inspect}" unless SENTIMENTS.include?(sentiment)

      escalate = data["escalate"]
      raise Error, "Invalid triage escalate flag: #{escalate.inspect}" unless [true, false].include?(escalate)

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

    # Models sometimes wrap JSON in ``` fences even with a schema.
    def parse_json(message)
      return message.content.deep_stringify_keys if message.content.is_a?(Hash)

      raw = message.content.to_s.strip.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
      data = JSON.parse(raw)
      raise Error, "Structured output was not a JSON object" unless data.is_a?(Hash)
      data
    end
  end
end
