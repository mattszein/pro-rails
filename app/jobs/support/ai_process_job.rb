module Support
  class AiProcessJob < ApplicationJob
    queue_as :support_ai

    # Responder failures are transient (provider hiccups): retry, and when retries run out hand
    # the ticket to a human so the user is never left waiting.
    retry_on SupportAi::Error, wait: :polynomially_longer, attempts: 3 do |job, error|
      ticket = Support::Ticket.find_by(id: job.arguments.first)
      Support::Ai::Fallback.call(ticket: ticket, error: error.message) if ticket
    end

    def perform(ticket_id, trigger, message_id = nil)
      ticket = Support::Ticket.find_by(id: ticket_id)
      return unless ticket
      return unless ticket.ai_analyzing?

      trigger_message = nil
      messages = ticket.conversation.messages
      if message_id
        trigger_message = messages.find_by(id: message_id)
        return unless trigger_message
        # A newer human message gets its own job: this debounces bursts.
        return unless messages.human.reorder(id: :desc).first&.id == trigger_message.id
        # Already answered (re-run).
        return if messages.ai.where("messages.id > ?", trigger_message.id).exists?
      elsif trigger == "ticket_created"
        return if messages.ai.exists?
      end

      case trigger
      when "ticket_created"
        run(Support::Ai::Flows::ProcessTicket, ticket: ticket, trigger: trigger)
      when "user_message"
        run(Support::Ai::Flows::ProcessReply, ticket: ticket, trigger: trigger, trigger_message: trigger_message)
      else
        raise ArgumentError, "Unknown AI trigger: #{trigger.inspect}"
      end
    end

    private

    def run(organizer, **context)
      result = organizer.call(**context)
      Rails.logger.info("Support AI #{organizer.name} halted for ticket #{context[:ticket].id}: #{result.error}") if result.failure?
    end
  end
end
