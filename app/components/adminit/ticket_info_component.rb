module Adminit
  class TicketInfoComponent < ApplicationViewComponent
    # Not ai_off tickets get an AI-state badge. info -> primary, neutral -> secondary,
    # warning -> orange, success -> green (Core::BadgeComponent themes).
    AI_STATE_THEMES = {
      "analyzing" => :primary,
      "awaiting_user" => :secondary,
      "handoff_requested" => :orange,
      "stepped_back" => :secondary,
      "resolved" => :green
    }.freeze

    option :ticket

    def status_theme
      helpers.ticket_status_theme(ticket.status)
    end

    def show_ai_state?
      !ticket.ai_off?
    end

    def ai_state_theme
      AI_STATE_THEMES.fetch(ticket.ai_state)
    end
  end
end
