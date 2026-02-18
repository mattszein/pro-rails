module Support
  class Ticket < ApplicationRecord
    self.table_name = "tickets"

    belongs_to :created, class_name: "Account", optional: true
    belongs_to :assigned, class_name: "Account", optional: true
    has_one :conversation, class_name: "Support::Conversation", dependent: :destroy
    has_many_attached :attachments

    enum :status, {open: 0, in_progress: 1, closed: 2}, default: :open, validate: {allow_nil: false}
    enum :category, {
      account_access: 0,
      technical_issue: 1,
      billing: 2,
      feature_request: 3,
      other: 4
    }, default: :account_access, validate: {allow_nil: false}
    default_scope { order(priority: :desc, created_at: :desc) }
    validates :title, :description, :status, :category, :created_id, presence: true
    validate :validate_attachments
    after_create :create_conversation

    broadcasts_to ->(ticket) { "tickets" },
      partial: "support/tickets/ticket_table"

    after_create_commit do |ticket|
      broadcast_append_later_to "admin_tickets",
        target: "admin_tickets",
        partial: "adminit/tickets/ticket_row"
    end

    after_destroy_commit do
      broadcast_remove_to "admin_tickets",
        target: ActionView::RecordIdentifier.dom_id(self, "admin")
    end

    after_update_commit do |ticket|
      # For the individual show page
      broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(ticket, "admin"),
        target: ActionView::RecordIdentifier.dom_id(ticket, "admin"),
        partial: "adminit/tickets/ticket"

      broadcast_replace_later_to "admin_tickets",
        target: ActionView::RecordIdentifier.dom_id(ticket, "admin"),
        partial: "adminit/tickets/ticket_row"
    end

    private

    def create_conversation
      create_conversation! if conversation.blank?
    end

    def validate_attachments
      return unless attachments.attached?

      # Validate number of attachments
      if attachments.count > FileUploadConfig.max_files_per_ticket
        errors.add(:attachments, "cannot exceed #{FileUploadConfig.max_files_per_ticket} files")
      end

      attachments.each do |attachment|
        # Validate file size
        if attachment.byte_size > FileUploadConfig.max_file_size_bytes
          errors.add(:attachments, "#{attachment.filename} is too large (max #{FileUploadConfig.max_file_size_mb}MB)")
        end

        # Validate content type
        unless FileUploadConfig.allowed_content_types_list.include?(attachment.content_type)
          errors.add(:attachments, "#{attachment.filename} has an invalid file type")
        end
      end
    end
  end
end
