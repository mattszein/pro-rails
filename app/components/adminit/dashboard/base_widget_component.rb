module Adminit
  module Dashboard
    # Shared wrapper for every widget body: consistent padding, vertical
    # scroll inside the container card, and a shared "nothing to show"
    # fallback so each widget doesn't hand-roll its own empty-state markup.
    class BaseWidgetComponent < ApplicationViewComponent
      option :empty, default: -> { false }
    end
  end
end
