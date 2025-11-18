class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :account

  validates :content, presence: true
  default_scope { order(created_at: :asc) }
  broadcasts_to :conversation, inserts_by: :append, target: ->(message) { "conversation_#{message.conversation.id}_messages" }, partial: "conversation/message"  # Custom partial path
end
