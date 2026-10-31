module Support
  module Messages
    # Saves a message built by the controller (context.message, account already set) and resumes
    # the AI when the requester's message needs it. Everything is decided under the ticket lock,
    # because the policy ran on possibly stale state (two tabs, or a ticket finished meanwhile):
    # - the requester must still be able to write (messageable?), so nobody writes while the AI
    #   is analyzing; the message and the awaiting_user -> analyzing flip are one transaction;
    # - an admin can only write on a ticket assigned to them (policy), and assigning already
    #   released the AI, so a non-requester message never meets an engaged AI: no flip, no job;
    # - the job is enqueued after the lock is released, only when this message resumed the AI.
    # Any other state (off, handed off, stepped back, resolved) has no AI side effects.
    class Create
      include Interactor

      delegate :message, to: :context

      def call
        ticket = message.conversation.ticket
        resumed = false
        ticket.with_lock do # reloads the ticket
          context.fail!(error: I18n.t("support.messages.not_sent")) if requester?(ticket) && !ticket.messageable?
          context.fail!(error: message.errors.full_messages.to_sentence) unless message.save
          if ticket.ai_awaiting_user?
            ticket.start_ai_analysis!
            resumed = true
          end
        end
        Support::AiProcessJob.enqueue(ticket, :user_message, message.id) if resumed
      end

      private

      def requester?(ticket) = message.account_id == ticket.created_id
    end
  end
end
