module Support
  module Ai
    # Locale-neutral "assistant is working" indicator, broadcast to the conversation stream.
    # Removing an element that is not on the page is harmless, so hide is always safe to call.
    module Typing
      module_function

      def show(ticket)
        conversation = ticket.conversation
        return unless conversation

        Turbo::StreamsChannel.broadcast_append_to(
          conversation,
          target: "support_conversation_#{conversation.id}_messages",
          partial: "support/conversations/typing",
          locals: {conversation: conversation}
        )
      end

      def hide(ticket)
        conversation = ticket.conversation
        return unless conversation

        Turbo::StreamsChannel.broadcast_remove_to(
          conversation,
          target: ActionView::RecordIdentifier.dom_id(conversation, :typing)
        )
      end
    end
  end
end
