module Support
  # The declared AI capability vocabulary and its in-memory registry — enumerable during boot,
  # migrations and asset builds, when no playbook rows need exist. Re-declared on every code
  # reload by config/initializers/support_ai_capabilities.rb (`install`), so edits hot-reload.
  #
  # SECURITY BOUNDARY: nothing declared here may read other users' data into a user-facing
  # prompt. `similar_tickets` is a flag for the admin-only note line; it never reaches a prompt.
  module AiCapabilities
    include DeclaredRegistry

    KINDS = %i[context tool flag].freeze
    STEPS = %i[handle respond apply_triage draft].freeze

    class << self
      def register(key:, kind:, steps:, tool_class: nil, default: false)
        key = key.to_sym
        raise ArgumentError, "unknown kind: #{kind.inspect}" unless KINDS.include?(kind)
        raise ArgumentError, "unknown steps: #{steps.inspect}" unless steps.any? && (steps - STEPS).empty?

        registry[key] = AiCapability.new(key: key, kind: kind, steps: steps.freeze, tool_class: tool_class, default: default)
      end

      def fetch(key) = registry.fetch(key.to_sym)

      def defaults = all.select(&:default)

      # Declared capabilities allowed to run in `step`, restricted to the keys a playbook enabled.
      # Unknown keys are dropped. This is the only gate between a playbook and what a step uses.
      def for_step(step, capabilities)
        enabled = Array(capabilities).map(&:to_s)
        all.select { |capability| capability.allowed_in?(step) && enabled.include?(capability.key.to_s) }
      end

      def install
        reset!

        register(key: :account_facts, kind: :context, steps: %i[handle respond], default: true)
        register(key: :past_tickets, kind: :context, steps: %i[handle respond], default: true)
        # Also prefetches matching articles into the prompt (retrieval-first) and drives the KB gap.
        register(key: :search_articles, kind: :tool, steps: %i[handle respond],
          tool_class: "SupportAi::Tools::SearchArticles", default: true)
        register(key: :similar_tickets, kind: :flag, steps: %i[handle], default: false)
        register(key: :vision_attachments, kind: :flag, steps: %i[handle], default: false)
        register(key: :investigate_note, kind: :flag, steps: %i[handle], default: true)
        register(key: :auto_set_priority, kind: :flag, steps: %i[apply_triage], default: true)
        register(key: :auto_correct_category, kind: :flag, steps: %i[apply_triage], default: false)
        register(key: :draft_replies, kind: :flag, steps: %i[draft], default: false)
      end
    end
  end
end
