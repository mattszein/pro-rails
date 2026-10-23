module Support
  module Ai
    # Shows the typing indicator and enqueues the AI job. Solid Queue uses a separate
    # database, so an enqueue failure must never undo the state change that came before it:
    # it is logged, the indicator is removed, and the safety-net sweep recovers the ticket.
    # Only enqueue errors are rescued; anything else is a bug and bubbles up.
    module Dispatch
      module_function

      def call(ticket, trigger, message_id = nil)
        Typing.show(ticket)
        Support::AiProcessJob.perform_later(ticket.id, trigger.to_s, message_id)
        true
      rescue ActiveJob::EnqueueError, ActiveRecord::ActiveRecordError => e
        Rails.logger.error("Support AI enqueue failed for ticket #{ticket.id} (#{trigger}): #{e.class}: #{e.message}")
        Typing.hide(ticket)
        false
      end
    end
  end
end
