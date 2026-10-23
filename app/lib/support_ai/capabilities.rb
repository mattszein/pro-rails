# Declares the AI capability vocabulary. Autoloaded (not an initializer) so
# edits hot-reload in development via config/initializers/support_ai_capabilities.rb.
#
# SECURITY BOUNDARY: the user-facing :respond step must never see other users'
# data. `similar_tickets` reads other requesters' tickets, so it is declared for
# :investigate ONLY (admin-facing); the registry's `steps` enforce it.
module SupportAi
  module Capabilities
    module_function

    def install
      Registry.reset!

      Registry.register(key: :account_facts, kind: :read, steps: %i[investigate respond],
        tool_class: "SupportAi::Tools::AccountFacts", default: true)
      Registry.register(key: :past_tickets, kind: :read, steps: %i[investigate respond],
        tool_class: "SupportAi::Tools::PastTickets", default: true)
      Registry.register(key: :similar_tickets, kind: :read, steps: %i[investigate],
        tool_class: "SupportAi::Tools::SimilarTickets", default: false)
      Registry.register(key: :search_articles, kind: :read, steps: %i[investigate respond],
        tool_class: "SupportAi::Tools::SearchArticles", default: true)
      Registry.register(key: :vision_attachments, kind: :read, steps: %i[investigate respond],
        tool_class: nil, default: false)
      Registry.register(key: :investigate_note, kind: :action, steps: %i[investigate],
        tool_class: nil, default: true)
      Registry.register(key: :auto_set_priority, kind: :action, steps: %i[apply_triage],
        tool_class: nil, default: true)
      Registry.register(key: :auto_correct_category, kind: :action, steps: %i[apply_triage],
        tool_class: nil, default: false)
      Registry.register(key: :suggest_articles, kind: :action, steps: %i[respond],
        tool_class: "SupportAi::Tools::SuggestArticles", default: true)
      Registry.register(key: :propose_resolution, kind: :action, steps: %i[respond],
        tool_class: "SupportAi::Tools::ProposeResolution", default: true)
      Registry.register(key: :request_human, kind: :action, steps: %i[respond],
        tool_class: "SupportAi::Tools::RequestHuman", default: true)
      Registry.register(key: :draft_replies, kind: :action, steps: %i[draft],
        tool_class: nil, default: false)
    end
  end
end
