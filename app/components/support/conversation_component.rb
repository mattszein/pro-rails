module Support
  class ConversationComponent < ApplicationViewComponent
    option :conversation
    option :messages

    def title
      "Conversation"
    end
  end
end
