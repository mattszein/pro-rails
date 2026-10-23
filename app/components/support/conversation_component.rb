module Support
  class ConversationComponent < ApplicationViewComponent
    option :conversation
    option :messages
    # Render the assistant "typing" indicator (the ticket is born analyzing and the broadcast
    # fires before the page loads).
    option :typing, default: -> { false }

    def title
      I18n.t("support.conversation.title")
    end
  end
end
