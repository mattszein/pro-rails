module Support
  # Data-only helpers for the conversation partials. They are also called while rendering Turbo
  # broadcasts (no request, no current_account), so they may only read from their arguments
  # and the database.
  module ConversationsHelper
    # Published articles an AI message links to, in the order the assistant listed them.
    def support_message_articles(message)
      return [] unless message.ai?

      ids = Array(message.metadata["article_ids"]).filter_map { |id| Integer(id, exception: false) }
      return [] if ids.empty?

      by_id = Support::Article.published_among(ids).index_by(&:id)
      ids.filter_map { |id| by_id[id] }
    end

    # The ticket (for ids only) when the "This solved it / No, I still need help" buttons may
    # render on `message`, else nil. Mirrors Support::TicketPolicy#resolve_with_ai? from data
    # alone; the requester-only gate is applied client-side by <turbo-show>, and stale buttons
    # on older messages are hidden by the conversation Stimulus controller.
    def support_message_resolution_ticket(message)
      return unless message.ai? && message.metadata["resolution_proposed"].present?

      conversation = message.conversation
      ticket = conversation.ticket
      return if !ticket.open? || !(ticket.ai_analyzing? || ticket.ai_awaiting_user?)

      latest_id = conversation.messages.reorder(created_at: :desc, id: :desc).pick(:id)
      ticket if latest_id == message.id
    end
  end
end
