module Support
  module Messages
    # Saves a message built by the controller (context.message, account already set) and
    # reconciles the AI state:
    # - an admin (not the requester) writing while the AI is engaged takes over from it;
    # - the requester writing while the AI waits resumes it; while it is analyzing, the job
    #   guards debounce, so we only enqueue.
    # Any other state (off, handed off, stepped back, resolved) has no AI side effects.
    class Create
      include Interactor

      delegate :message, to: :context

      def call
        context.fail!(error: message.errors.full_messages.to_sentence) unless message.save

        ticket = message.conversation.ticket
        action = reconcile_ai(ticket)
        Support::Ai::Typing.hide(ticket) if action == :released_while_analyzing
        Support::Ai::Dispatch.call(ticket, "user_message", message.id) if %i[resume enqueue].include?(action)
      end

      private

      def reconcile_ai(ticket)
        action = nil
        ticket.with_lock do
          creator = message.account_id == ticket.created_id
          if !creator && ticket.ai_engaged?
            was_analyzing = ticket.ai_analyzing?
            ticket.release_ai!
            ticket.notes.create!(account: nil, kind: :system, body: "Support took over from AI.")
            action = was_analyzing ? :released_while_analyzing : :released
          elsif creator && ticket.ai_awaiting_user?
            ticket.start_ai_analysis!
            action = :resume
          elsif creator && ticket.ai_analyzing?
            action = :enqueue
          end
        end
        action
      end
    end
  end
end
