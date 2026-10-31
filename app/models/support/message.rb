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

    # Published articles an AI message links to, in the order the assistant listed them.
    def suggested_articles
      return [] unless ai?

      ids = Array(metadata["article_ids"]).filter_map { |id| Integer(id, exception: false) }
      return [] if ids.empty?

      by_id = Support::Article.published_among(ids).index_by(&:id)
      ids.filter_map { |article_id| by_id[article_id] }
    end

    def resolution_proposed?
      ai? && metadata["resolution_proposed"].present?
    end

    def latest?
      conversation.messages.reorder(created_at: :desc, id: :desc).pick(:id) == id
    end

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
