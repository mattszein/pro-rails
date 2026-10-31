module Support
  module Ai
    module Flows
      # Runs on ticket creation: triage, playbook, apply, handle (one chat: note + reply), finalize.
      # Context in: ticket, trigger (:ticket_created).
      class ProcessTicket
        include Interactor::Organizer

        organize Triage, SelectPlaybook, ApplyTriage, Handle, Finalize
      end
    end
  end
end
