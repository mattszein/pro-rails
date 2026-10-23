module SupportAi
  module Tools
    class RequestHuman < ActionBase
      description "Hand this ticket to a human support agent. Use when the user asks for a person, the issue " \
        "needs account access or billing changes, or you cannot resolve it. Argument: reason."

      parameter :reason, description: "Short explanation for the human agent"

      def execute(reason:)
        collector.request_handoff(reason.to_s.truncate(500))
        "A human agent has been requested. Tell the user a person will follow up."
      end
    end
  end
end
