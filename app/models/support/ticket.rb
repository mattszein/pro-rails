module Support
  class Ticket < ApplicationRecord
    class InvalidTransition < StandardError; end

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
    scope :prioritized, -> { order(priority: :desc, created_at: :desc) }
    scope :search_title, ->(query) { where("title ILIKE ?", "%#{sanitize_sql_like(query)}%") }
    scope :assigned_to, ->(account_id) { where(assigned_id: account_id) }
    scope :title_matching_any, ->(terms) {
      patterns = Array(terms).map { |term| "%#{sanitize_sql_like(term.to_s)}%" }
      patterns.empty? ? none : where(patterns.map { "title ILIKE ?" }.join(" OR "), *patterns)
    }

    validates :title, :description, :status, :category, :created_id, presence: true
    validate :validate_attachments

    # Dashboard widget reads. `reorder` overrides the default_scope ordering.
    scope :recent_open, ->(limit: 10) { open.reorder(updated_at: :desc).limit(limit) }
    scope :assigned_open_for, ->(account, limit: 10) { assigned_to(account.id).open.reorder(updated_at: :desc).limit(limit) }

    # Order matters: the takeover release must run before the timestamp stamp so
    # both land in the same save.
    before_save :release_ai_on_assignment, unless: :new_record?
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
      in_progress? || reopened? || (open? && ai_engaged?)
    end

    def ai_engaged?
      ai_analyzing? || ai_awaiting_user? || ai_handoff_requested?
    end

    # Newest AI runs first, for the admin "AI activity" panel.
    def recent_ai_runs(limit = 20) = ai_runs.recent(limit)

    # The AI is still working on the ticket: the "This solved it" prompt may be actionable.
    def awaiting_ai_resolution?
      open? && (ai_analyzing? || ai_awaiting_user?)
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

    def start_ai_analysis!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_start_ai_analysis") unless ai_off? || ai_awaiting_user?
      update!(ai_state: :analyzing)
    end

    def disable_ai!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_disable_ai") unless ai_analyzing?
      update!(ai_state: :off)
    end

    def await_user_reply!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_await_user_reply") unless ai_analyzing?
      update!(ai_state: :awaiting_user)
    end

    def request_ai_handoff!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_request_ai_handoff") unless ai_analyzing? || ai_awaiting_user?
      update!(ai_state: :handoff_requested)
    end

    def release_ai!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_release_ai") unless ai_engaged?
      update!(ai_state: :stepped_back)
    end

    def resolve_with_ai!
      raise InvalidTransition, I18n.t("ticket.transitions.can_only_resolve_with_ai") unless open? && ai_awaiting_user?
      update!(status: :finished, ai_state: :resolved)
    end

    private

    # What the message form area renders: the composer, or the status banner/reopen form of the
    # current status.
    def message_form_variant(status: self.status, ai_state: self.ai_state)
      messageable = self.class.new(status: status, ai_state: ai_state).messageable?
      messageable ? :composer : status.to_s
    end

    def message_form_variant_before_last_save
      message_form_variant(status: status_before_last_save || status, ai_state: ai_state_before_last_save || ai_state)
    end

    # Data integrity: a human taking the ticket always silences the AI, whichever
    # path set assigned_id (Take, the Adminit form, console).
    def release_ai_on_assignment
      self.ai_state = :stepped_back if will_save_change_to_assigned_id? && assigned_id.present? && ai_engaged?
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
