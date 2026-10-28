module Support
  class AiPlaybook < ApplicationRecord
    self.table_name = "support_ai_playbooks"

    PRIORITY_RANGE = (1..5)

    belongs_to :audience, optional: true
    has_many :ai_runs, class_name: "Support::AiRun", foreign_key: :playbook_id, inverse_of: :playbook, dependent: :nullify

    enum :mode, {triage_only: 0, assist: 1}, default: :assist, validate: {allow_nil: false}

    validates :name, presence: true, uniqueness: true
    validates :min_priority, :max_priority, numericality: {only_integer: true, in: PRIORITY_RANGE}, allow_nil: true
    validates :max_ai_turns, :idle_reminder_after_hours, :idle_handoff_after_hours,
      numericality: {only_integer: true, greater_than_or_equal_to: 1}
    validate :priority_range_ordered
    validate :handoff_after_reminder
    validate :categories_known
    validate :capabilities_registered
    validate :single_default

    before_validation :normalize_capabilities
    before_destroy :prevent_default_destroy

    scope :enabled, -> { where(enabled: true) }

    def self.default_playbook = find_by(is_default: true)

    # Playbooks as shown in the admin: custom ones by name, the default last since it is only the fallback.
    scope :listed, -> { order(:is_default, :name) }

    # The most specific enabled non-default playbook whose conditions fit (ties go to the oldest),
    # else the enabled default, else nil.
    def self.match_for(ticket, priority: nil)
      priority ||= ticket.priority
      candidates = enabled.order(:id).includes(audience: :audience_conditions).to_a
      custom = candidates.reject(&:is_default?).select { |playbook| playbook.matches?(ticket, priority: priority) }
      custom.max_by { |playbook| [playbook.specificity, -playbook.id] } || candidates.find(&:is_default?)
    end

    # Number of conditions set: categories, a priority bound (either), an audience.
    def specificity
      [categories.any?, min_priority || max_priority, audience_id].count(&:present?)
    end

    def matches?(ticket, priority: nil)
      priority ||= ticket.priority
      category_match?(ticket) && priority_match?(priority) && audience_match?(ticket)
    end

    def category_keys
      categories.filter_map { |value| Support::Ticket::CATEGORIES.key(value)&.to_s }
    end

    def category_keys=(keys)
      self.categories = Array(keys).compact_blank.filter_map { |key| Support::Ticket::CATEGORIES[key.to_sym] }
    end

    def capability?(key) = capabilities.include?(key.to_s)

    # Declared capabilities this playbook enabled that may run in `step`.
    def capabilities_for(step) = Support::AiCapabilities.for_step(step, capabilities)

    def breadcrumb_title = name

    private

    def category_match?(ticket)
      categories.empty? || categories.include?(Support::Ticket::CATEGORIES[ticket.category.to_sym])
    end

    def priority_match?(priority)
      return true if min_priority.nil? && max_priority.nil?
      return false if priority.nil?

      (min_priority.nil? || priority >= min_priority) && (max_priority.nil? || priority <= max_priority)
    end

    def audience_match?(ticket)
      audience.nil? || (ticket.created.present? && audience.matches?(ticket.created))
    end

    def priority_range_ordered
      return if min_priority.nil? || max_priority.nil? || min_priority <= max_priority

      errors.add(:max_priority, :greater_than_or_equal_to, count: min_priority)
    end

    def handoff_after_reminder
      return if idle_reminder_after_hours.nil? || idle_handoff_after_hours.nil?
      return if idle_handoff_after_hours >= idle_reminder_after_hours

      errors.add(:idle_handoff_after_hours, :greater_than_or_equal_to, count: idle_reminder_after_hours)
    end

    def categories_known
      unknown = Array(categories) - Support::Ticket::CATEGORIES.values
      errors.add(:categories, :invalid) if unknown.any?
    end

    # Stored as unique strings; blank entries (the empty hidden field of a
    # checkbox group) are dropped.
    def normalize_capabilities
      self.capabilities = Array(capabilities).map { |key| key.to_s.strip }.compact_blank.uniq
    end

    def capabilities_registered
      unknown = Array(capabilities).reject { |key| Support::AiCapabilities.registered?(key) }
      errors.add(:capabilities, :not_registered) if unknown.any?
    end

    def single_default
      return unless is_default?
      return unless self.class.where(is_default: true).where.not(id: id).exists?

      errors.add(:is_default, :taken)
    end

    def prevent_default_destroy
      return unless is_default?

      errors.add(:base, I18n.t("activerecord.errors.models.support/ai_playbook.attributes.base.cannot_destroy_default"))
      throw :abort
    end
  end
end
