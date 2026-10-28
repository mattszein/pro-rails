module Support
  class ConversationComponent < ApplicationViewComponent
    option :conversation
    option :messages

    def title
      I18n.t("support.conversation.title")
    end
  end
end
