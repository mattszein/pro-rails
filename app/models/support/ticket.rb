module Support
  class Ticket < ApplicationRecord
    class InvalidTransition < StandardError; end

    self.table_name = "tickets"

    belongs_to :created, class_name: "Account", optional: true
    belongs_to :assigned, class_name: "Account", optional: true
    has_one :conversation, class_name: "Support::Conversation", dependent: :destroy
    has_many :notes, class_name: "Support::Note", dependent: :destroy
    has_many_attached :attachments

    enum :status, {
      open: 0,
      in_progress: 1,
      finished: 2,
      reopen_requested: 3,
      reopened: 4,
      closed: 5
    }, default: :open, validate: {allow_nil: false}
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

    after_update_commit do |ticket|
      # Admin show page
      broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(ticket, "admin"),
        target: ActionView::RecordIdentifier.dom_id(ticket, "admin"),
        partial: "adminit/tickets/ticket"

      # Admin index page
      broadcast_replace_later_to "admin_tickets",
        target: ActionView::RecordIdentifier.dom_id(ticket, "admin"),
        partial: "adminit/tickets/ticket_row"

      # User show page — update message form area on status change
      broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(ticket),
        target: ActionView::RecordIdentifier.dom_id(ticket, "message_form"),
        partial: "support/conversations/message_form_status"
    end

    def messageable?
      in_progress? || reopened?
    end

    def finish!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_finish") unless in_progress? || reopened?
      update!(status: :finished)
    end

    def reopen!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_reopen") unless finished?
      update!(status: :reopened)
    end

    def request_reopen!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_request_reopen") unless finished?
      update!(status: :reopen_requested)
    end

    def accept_reopen!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_accept_reopen") unless reopen_requested?
      update!(status: :reopened)
    end

    def reject_reopen!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_reject_reopen") unless reopen_requested?
      update!(status: :closed)
    end

    private

    def create_conversation
      create_conversation! if conversation.blank?
    end

    def validate_attachments
      return unless attachments.attached?

      # Validate number of attachments
      if attachments.count > FileUploadConfig.max_files_per_ticket
        errors.add(:attachments, I18n.t("activerecord.errors.models.support/ticket.attributes.attachments.too_many_files", max_files: FileUploadConfig.max_files_per_ticket))
      end

      attachments.each do |attachment|
        # Validate file size
        if attachment.byte_size > FileUploadConfig.max_file_size_bytes
          errors.add(:attachments, I18n.t("activerecord.errors.models.support/ticket.attributes.attachments.file_too_large", filename: attachment.filename, max_size: FileUploadConfig.max_file_size_mb))
        end

        # Validate content type
        unless FileUploadConfig.allowed_content_types_list.include?(attachment.content_type)
          errors.add(:attachments, I18n.t("activerecord.errors.models.support/ticket.attributes.attachments.invalid_file_type", filename: attachment.filename))
        end
      end
    end
  end
end
