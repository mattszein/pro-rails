module Llm
  module Tools
    # Base for every LLM tool. Tools never rescue: errors surface as Llm::Error from the Runner.
    # Subclasses take their own context (record, user...) as keyword arguments and pass `budget:`
    # up; any other keyword is ignored here.
    class Base < RubyLLM::Tool
      # "search_articles" rather than ruby_llm's namespaced default.
      def self.tool_name = name.demodulize.underscore

      def initialize(budget: nil, **)
        super()
        @budget = budget
      end

      # RubyLLM's dispatch seam (Chat#execute_tool -> tool.call(**args, tool_call:)). Goes through
      # the call's ToolBudget: identical calls come from cache, a spent budget answers with a
      # limit message without running `execute`. Without a budget it behaves like RubyLLM::Tool.
      def call(**arguments)
        return super unless budget

        tool_arguments = arguments.except(:tool_call)
        budget.run(self.class.tool_name, tool_arguments) { super }
      end

      private

      attr_reader :budget
    end
  end
end
