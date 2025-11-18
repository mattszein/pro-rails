class Conversation::ConversationComponent < ViewComponent::Base
  attr_reader :conversation, :messages

  def initialize(conversation:, messages:)
    @conversation = conversation
    @messages = messages
  end

  def title
    "Conversation"
  end
end
