module SupportAi
  module Capabilities
    # A declared AI capability a playbook can switch on. `kind` is :read (reads
    # data) or :action (changes something). `steps` lists the pipeline steps the
    # capability may run in. `tool_class` is the NAME of the RubyLLM tool class
    # (a String, never constantized at declaration; tools are built later) or nil
    # when the capability is not a tool. `default` marks it enabled on the seeded
    # default playbook.
    Capability = Data.define(:key, :kind, :steps, :tool_class, :default) do
      def read? = kind == :read

      def action? = kind == :action

      def allowed_in?(step) = steps.include?(step.to_sym)
    end
  end
end
