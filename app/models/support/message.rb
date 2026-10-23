module Support
  class Message < ApplicationRecord
    self.table_name = "messages"

    belongs_to :conversation, class_name: "Support::Conversation"
    belongs_to :account, optional: true

    enum :sender, {human: 0, ai: 1}, default: :human, validate: {allow_nil: false}

    validates :content, presence: true
    validate :account_matches_sender
    scope :chronological, -> { reorder(created_at: :asc, id: :asc) }
    default_scope { order(created_at: :asc) }

    broadcasts_to :conversation, inserts_by: :append, target: ->(message) { "support_conversation_#{message.conversation.id}_messages" }, partial: "support/conversations/message"

    private

    def account_matches_sender
      if human? && account.blank?
        errors.add(:account, :blank)
      elsif ai? && account.present?
        errors.add(:account, :present)
      end
    end
  end
end
