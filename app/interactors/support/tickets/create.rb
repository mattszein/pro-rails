module Support
  module Tickets
    # Persists a ticket built by the controller (context.ticket). When the support assistant is
    # globally enabled and a playbook exists, the ticket is born `analyzing` and the AI job is
    # enqueued once the record is committed. Enqueue failures never undo the ticket.
    class Create
      include Interactor

      delegate :ticket, to: :context

      def call
        ticket.ai_state = :analyzing if ai_available?

        unless ticket.save
          context.fail!(error: ticket.errors.full_messages.to_sentence)
        end

        Support::Ai::Dispatch.call(ticket, "ticket_created") if ticket.ai_analyzing?
      end

      private

      def ai_available?
        SupportAiConfig.enabled && Support::AiPlaybook.enabled.exists?
      end
    end
  end
end
