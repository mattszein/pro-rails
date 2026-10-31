module Support
  # A declared AI capability a playbook can switch on. `kind` is how it reaches the model:
  # :context (prefetched by code into the prompt), :tool (a function the model may call) or
  # :flag (a switch that changes what code does, no model involvement). `steps` lists the
  # pipeline steps it applies to. `tool_class` is the NAME of the RubyLLM tool class (a String,
  # never constantized at declaration) or nil. `default` marks it enabled on the seeded default
  # playbook.
  AiCapability = Data.define(:key, :kind, :steps, :tool_class, :default) do
    def context? = kind == :context

    def tool? = kind == :tool

    def flag? = kind == :flag

    def allowed_in?(step) = steps.include?(step.to_sym)
  end
end
