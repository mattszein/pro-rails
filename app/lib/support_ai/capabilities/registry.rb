module SupportAi
  module Capabilities
    # In-memory store of the declared capability set — enumerable during boot,
    # migrations and asset builds, when no playbook rows need exist.
    module Registry
      include DeclaredRegistry

      KINDS = %i[read action].freeze
      STEPS = %i[investigate respond apply_triage draft].freeze

      class << self
        def register(key:, kind:, steps:, tool_class: nil, default: false)
          key = key.to_sym
          raise ArgumentError, "unknown kind: #{kind.inspect}" unless KINDS.include?(kind)
          raise ArgumentError, "unknown steps: #{steps.inspect}" unless steps.any? && (steps - STEPS).empty?

          registry[key] = Capability.new(key: key, kind: kind, steps: steps.freeze, tool_class: tool_class, default: default)
        end

        def fetch(key) = registry.fetch(key.to_sym)

        def defaults = all.select(&:default)

        # Declared capabilities allowed to run in `step`, restricted to the keys
        # a playbook enabled. Unknown keys are dropped. This is the only gate
        # between a playbook's capability list and what a step may use.
        def for_step(step, capabilities)
          enabled = Array(capabilities).map(&:to_s)
          all.select { |capability| capability.allowed_in?(step) && enabled.include?(capability.key.to_s) }
        end
      end
    end
  end
end
