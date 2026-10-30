module Support
  module Messages
    # Saves a message built by the controller (context.message, account already set) and
    # reconciles the AI state:
    # - an admin can only write on a ticket assigned to them (policy), and assigning already
    #   released the AI, so a non-requester message never changes the AI state;
    # - the requester writing while the AI waits resumes it; while it is analyzing, the job
    #   guards debounce, so we only enqueue.
    # Any other state (off, handed off, stepped back, resolved) has no AI side effects.
    class Create
      include Interactor

      delegate :message, to: :context

      def call
        context.fail!(error: message.errors.full_messages.to_sentence) unless message.save

        ticket = message.conversation.ticket
        Support::Ai::Dispatch.call(ticket, "user_message", message.id) if sync_ai_state(ticket)
      end

      private

      # Under the ticket lock, applies the AI state change this message causes and returns whether
      # the AI job must run (the caller dispatches it after the lock is released).
      #   who writes   x AI state       -> effect
      #   non-requester x anything       -> nothing (assigned, so the AI is already stepped back)
      #   requester     x awaiting_user  -> start_ai_analysis!; job
      #   requester     x analyzing      -> no state change; job (debounces to the newest message)
      #   anyone        x anything else  -> nothing
      def sync_ai_state(ticket)
        run_ai = false
        ticket.with_lock do
          requester = message.account_id == ticket.created_id
          if requester && ticket.ai_awaiting_user?
            ticket.start_ai_analysis!
            run_ai = true
          elsif requester && ticket.ai_analyzing?
            run_ai = true
          end
        end
        run_ai
      end
    end
  end
end
