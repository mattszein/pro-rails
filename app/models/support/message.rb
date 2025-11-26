module Support
  class Message < ApplicationRecord
    self.table_name = "messages"

    belongs_to :conversation, class_name: "Support::Conversation"
    belongs_to :account

    validates :content, presence: true
    default_scope { order(created_at: :asc) }

    broadcasts_to :conversation, inserts_by: :append, target: ->(message) { "support_conversation_#{message.conversation.id}_messages" }, partial: "support/conversations/message"
  end
end
