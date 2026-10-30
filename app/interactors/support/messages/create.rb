module Support
  module Messages
    # Saves a message built by the controller (context.message, account already set) and resumes
    # the AI when the requester's message needs it:
    # - an admin can only write on a ticket assigned to them (policy), and assigning already
    #   released the AI, so a non-requester message never meets an engaged AI;
    # - the requester writing while the AI waits (awaiting_user) resumes it (-> analyzing) under
    #   the ticket lock, then the job is enqueued after the lock is released;
    # - while it is already analyzing, only the job is enqueued (it debounces to the newest message).
    # Any other state (off, handed off, stepped back, resolved) has no AI side effects.
    class Create
      include Interactor

      delegate :message, to: :context

      def call
        context.fail!(error: message.errors.full_messages.to_sentence) unless message.save

        ticket = message.conversation.ticket
        Support::AiProcessJob.enqueue(ticket, "user_message", message.id) if resume_ai(ticket)
      end

      private

      # awaiting_user -> analyzing under the lock (fresh state); returns whether the AI is analyzing.
      def resume_ai(ticket)
        ticket.with_lock do
          ticket.start_ai_analysis! if ticket.ai_awaiting_user?
          ticket.ai_analyzing?
        end
      end
    end
  end
end
