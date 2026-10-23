module SupportAi
  module Tools
    # Action tools only RECORD their effect on the collector.
    class ActionBase < Base
      def self.action? = true

      def initialize(ticket:, collector:, budget: nil)
        super(ticket: ticket, budget: budget)
        @collector = collector
      end

      private

      attr_reader :collector
    end
  end
end
