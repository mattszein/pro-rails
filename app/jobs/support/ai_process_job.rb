module Support
  class AiProcessJob < ApplicationJob
    queue_as :support_ai

    # Responder failures are transient (provider hiccups): retry, and when retries run out hand
    # the ticket to a human so the user is never left waiting.
    retry_on Llm::Error, wait: :polynomially_longer, attempts: 3 do |job, error|
      ticket = Support::Ticket.find_by(id: job.arguments.first)
      Support::Ai::Fallback.call(ticket: ticket, error: error.message) if ticket
    end

    # trigger => organizer. The only place that says which triggers start the AI and what they run;
    # the keys are Support::AiRun run_trigger names.
    FLOWS = {
      ticket_created: Support::Ai::Flows::ProcessTicket,
      user_message: Support::Ai::Flows::ProcessReply
    }.freeze

    # Enqueues the job after a state change has been committed. Solid Queue uses a separate
    # database, so an enqueue failure must never undo that change: it is logged and reported as
    # false. (No safety-net sweep recovers the ticket yet; it is planned in support-ai-assist.)
    # Only enqueue errors are rescued; anything else is a bug and bubbles up, including an
    # unknown trigger (KeyError).
    def self.enqueue(ticket, trigger, message_id = nil)
      FLOWS.fetch(trigger)
      perform_later(ticket.id, trigger, message_id)
      true
    rescue ActiveJob::EnqueueError, ActiveRecord::ActiveRecordError => e
      Rails.logger.error("Support AI enqueue failed for ticket #{ticket.id} (#{trigger}): #{e.class}: #{e.message}")
      false
    end

    def perform(ticket_id, trigger, message_id = nil)
      trigger = trigger.to_sym # jobs already in the queue carry strings
      flow = FLOWS.fetch(trigger)

      ticket = Support::Ticket.find_by(id: ticket_id)
      return unless ticket

      trigger_message = ticket.conversation.messages.find_by(id: message_id) if message_id
      return if message_id && trigger_message.nil?
      # Cheap early exit so a stale pass spends no LLM call; Finalize re-checks it under the lock.
      return unless ticket.ai_analyzing?

      result = flow.call(ticket: ticket, trigger: trigger, trigger_message: trigger_message)
      Rails.logger.info("Support AI #{flow.name} halted for ticket #{ticket.id}: #{result.error}") if result.failure?
    end
  end
end
