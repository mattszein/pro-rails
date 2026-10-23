module Support
  module Ai
    # Runs when the user writes while the AI is engaged: respond and finalize.
    # Context in: ticket, trigger_message, trigger ("user_message").
    class ProcessReply
      include Interactor::Organizer

      organize SelectPlaybook, Respond, Finalize
    end
  end
end
