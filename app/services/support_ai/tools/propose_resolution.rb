module SupportAi
  module Tools
    class ProposeResolution < ActionBase
      description "Call when your reply likely solves the problem, so the user can confirm it. Takes no arguments."

      def execute
        collector.propose_resolution
        "Recorded. The user will be asked to confirm the issue is solved."
      end
    end
  end
end
