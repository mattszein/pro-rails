module Support
  # User-facing assistant status: a banner for the AI state plus a persistent "Talk to a person"
  # button. Rendered on the ticket page and re-broadcast on ticket updates, so it reads only from
  # the ticket (no request context); the button is limited to the requester with <turbo-show>.
  class AiStatusComponent < ApplicationViewComponent
    BANNER_VARIANTS = {
      ai_analyzing: :info,
      ai_awaiting_user: :info,
      ai_handoff_requested: :warning,
      ai_resolved: :success
    }.freeze

    option :ticket

    def banner_key
      return :ai_resolved if ticket.ai_resolved?

      if ticket.open?
        return :ai_analyzing if ticket.ai_analyzing?
        return :ai_awaiting_user if ticket.ai_awaiting_user?
        :ai_handoff_requested if ticket.ai_handoff_requested?
      end
    end

    def banner_variant
      BANNER_VARIANTS.fetch(banner_key)
    end

    def banner_text
      I18n.t("support.ticket_status_banner.#{banner_key}")
    end

    # Mirrors Support::TicketPolicy#request_human? from data alone.
    def talk_to_person?
      ticket.open? && ticket.ai_awaiting_user?
    end
  end
end
