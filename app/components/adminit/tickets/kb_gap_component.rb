module Adminit
  module Tickets
    # "KB gap" badge plus a "Create article" link prefilled from the ticket. Rendered for a `handle` AiRun
    # whose output flags `kb_gap`. Receives the ticket only: no queries, no request-context helpers (it lives
    # inside a broadcast partial). No explicit locale param: the `:locale` route scope already puts the current
    # locale in the path (/en/..., /es/...) and `ArticlesController#new` prefills the article locale from it.
    # Forcing the default locale here would switch an admin's UI language.
    class KbGapComponent < ApplicationViewComponent
      option :ticket

      def self.gap?(run)
        run.step.to_s == "handle" && run.output.is_a?(Hash) && run.output["kb_gap"] == true
      end

      def article_path
        new_adminit_article_path(title: ticket.title, category: ticket.category)
      end
    end
  end
end
