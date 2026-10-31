module Support
  class Ticket < ApplicationRecord
    include Transitions

    AI_STEPPED_BACK_NOTE = "AI stepped back."

    class InvalidTransition < DomainError; end
    class AlreadyAssigned < InvalidTransition; end

    # Shared with Support::Article so ticket and article categories cannot drift.
    CATEGORIES = {
      account_access: 0,
      technical_issue: 1,
      billing: 2,
      feature_request: 3,
      other: 4
    }.freeze

    self.table_name = "tickets"

    belongs_to :created, class_name: "Account", optional: true
    belongs_to :assigned, class_name: "Account", optional: true
    has_one :conversation, class_name: "Support::Conversation", dependent: :destroy
    has_many :notes, class_name: "Support::Note", dependent: :destroy
    has_many :ai_runs, class_name: "Support::AiRun", dependent: :destroy
    has_many_attached :attachments

    enum :status, {
      open: 0,
      in_progress: 1,
      finished: 2,
      reopen_requested: 3,
      reopened: 4,
      closed: 5
    }, default: :open, validate: {allow_nil: false}
    enum :ai_state, {
      off: 0,
      analyzing: 1,
      awaiting_user: 2,
      handoff_requested: 3,
      stepped_back: 4,
      resolved: 5
    }, prefix: :ai, validate: {allow_nil: false}
    enum :category, CATEGORIES, default: :account_access, validate: {allow_nil: false}

    validates :title, :description, :status, :category, :created_id, presence: true
    validate :validate_attachments
    validate :ai_not_engaged_while_assigned

    scope :prioritized, -> { order(priority: :desc, created_at: :desc) }
    scope :search_title, ->(query) { where("title ILIKE ?", "%#{sanitize_sql_like(query)}%") }
    scope :assigned_to, ->(account_id) { where(assigned_id: account_id) }
    scope :title_matching_any, ->(terms) {
      patterns = Array(terms).map { |term| "%#{sanitize_sql_like(term.to_s)}%" }
      patterns.empty? ? none : where(patterns.map { "title ILIKE ?" }.join(" OR "), *patterns)
    }
    # Dashboard widget reads. `reorder` drops any ordering from a chained scope (e.g. `prioritized`).
    scope :recent_open, ->(limit: 10) { open.reorder(updated_at: :desc).limit(limit) }
    scope :assigned_open_for, ->(account, limit: 10) { assigned_to(account.id).open.reorder(updated_at: :desc).limit(limit) }

    before_save :stamp_ai_state_changed_at, if: :will_save_change_to_ai_state?
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

      # User show page: assistant status banner (state/status changes only).
      if saved_change_to_status? || saved_change_to_ai_state?
        broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(ticket),
          target: ActionView::RecordIdentifier.dom_id(ticket, :ai_status),
          partial: "support/conversations/ai_status"
      end

      # Composer area, re-broadcast ONLY when its variant changes (composer vs. one of the status
      # banners), never on every update: replacing a live composer would wipe the draft the user
      # is typing (e.g. when the assistant's reply flips ai_state while they write).
      if message_form_variant != message_form_variant_before_last_save
        broadcast_replace_later_to ActionView::RecordIdentifier.dom_id(ticket),
          target: ActionView::RecordIdentifier.dom_id(ticket, "message_form"),
          partial: "support/conversations/message_form"
      end
    end

    def breadcrumb_title = "##{id} #{title}"

    def messageable?
      in_progress? || reopened? || (open? && (ai_awaiting_user? || ai_handoff_requested?))
    end

    def ai_engaged?
      ai_analyzing? || ai_awaiting_user? || ai_handoff_requested?
    end

    # An AI pass is current while the AI owns the ticket and the user has not written since its
    # trigger message. A ticket_created pass has no trigger message, so any human message makes it stale.
    def ai_pass_current?(trigger_message = nil)
      ai_analyzing? && !conversation.messages.human.where("messages.id > ?", trigger_message&.id || 0).exists?
    end

    # Newest AI runs first, for the admin "AI activity" panel.
    def recent_ai_runs(limit = 20) = ai_runs.recent(limit)

    # The AI is still working on the ticket: the "This solved it" prompt may be actionable.
    def awaiting_ai_resolution?
      open? && ai_awaiting_user?
    end

    # The requester's other tickets, newest first. Read by the support assistant.
    def self.history_for(ticket, limit: 10)
      where(created_id: ticket.created_id).where.not(id: ticket.id).reorder(created_at: :desc, id: :desc).limit(limit)
    end

    # Finished/closed tickets of the same category opened by OTHER accounts whose title
    # matches any of `terms`. Only for admin-facing tooling: never expose requester data.
    def self.resolved_similar_to(ticket, terms:, limit: 5)
      where(category: ticket.category, status: [:finished, :closed])
        .where.not(created_id: ticket.created_id)
        .title_matching_any(terms)
        .reorder(created_at: :desc, id: :desc)
        .limit(limit)
    end

    # Stats for the adminit dashboard tickets analytics widget.
    def self.dashboard_stats
      by_status = reorder(nil).group(:status).count
      needs_human = reorder(nil).open.ai_handoff_requested.count

      {
        total: by_status.values.sum,
        open: by_status["open"] || 0,
        in_progress: by_status["in_progress"] || 0,
        resolved: (by_status["finished"] || 0) + (by_status["closed"] || 0),
        needs_human: needs_human,
        by_status: by_status
      }
    end

    private

    # What the message form area renders: the composer, or the status banner/reopen form of the
    # current status. The requester is locked out while the assistant analyzes (one pass at a time).
    def message_form_variant(status: self.status, ai_state: self.ai_state)
      probe = self.class.new(status: status, ai_state: ai_state)
      return :composer if probe.messageable?

      (probe.open? && probe.ai_analyzing?) ? :ai_analyzing : status.to_s
    end

    def message_form_variant_before_last_save
      message_form_variant(status: status_before_last_save || status, ai_state: ai_state_before_last_save || ai_state)
    end

    # A human owns the ticket or the AI works on it, never both. assign! silences the AI in the
    # same update; start_ai_analysis! refuses assigned tickets.
    def ai_not_engaged_while_assigned
      errors.add(:ai_state, :engaged_while_assigned) if assigned_id.present? && ai_engaged?
    end

    def stamp_ai_state_changed_at
      self.ai_state_changed_at = Time.current
    end

    def create_conversation
      create_conversation! if conversation.blank?
    end

    def validate_attachments
      return unless attachments.attached?

      # Validate number of attachments
      if attachments.size > FileUploadConfig.max_files_per_ticket
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
