module Support
  module Ai
    # Runs on ticket creation: triage, playbook, apply, handle (one chat: findings + reply), similar cases (optional, admin-only), finalize.
    # Context in: ticket, trigger ("ticket_created").
    class ProcessTicket
      include Interactor::Organizer

      organize Triage, SelectPlaybook, ApplyTriage, Handle, SimilarCases, Finalize
    end
  end
end
