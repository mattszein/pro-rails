module SupportAi
  module Tools
    # Base for every assistant tool. Tools are built per call with the ticket they act for and
    # never rescue: errors surface as SupportAi::Error from the Responder.
    class Base < RubyLLM::Tool
      # "search_articles" rather than ruby_llm's namespaced default.
      def self.tool_name = name.demodulize.underscore

      def initialize(ticket:, budget: nil, **)
        super()
        @ticket = ticket
        @budget = budget
      end

      # RubyLLM's dispatch seam (Chat#execute_tool -> tool.call(**args, tool_call:)). Goes through
      # the step's ToolBudget: identical calls come from cache, a spent budget answers with a
      # limit message without running `execute`. Without a budget it behaves like RubyLLM::Tool.
      def call(**arguments)
        return super unless budget

        tool_arguments = arguments.except(:tool_call)
        budget.run(self.class.tool_name, tool_arguments) { super }
      end

      private

      attr_reader :ticket, :budget
    end
  end
end
