module Support
  class TicketStatusBannerComponent < ApplicationViewComponent
    option :ticket

    THEME_MAPPINGS = {
      green: "bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-800 dark:text-green-300",
      yellow: "bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800 text-yellow-800 dark:text-yellow-300",
      red: "bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-800 dark:text-red-300",
      orange: "bg-orange-50 dark:bg-orange-900/20 border-orange-200 dark:border-orange-800 text-orange-800 dark:text-orange-300"
    }.freeze

    def render?
      !ticket.messageable?
    end

    def theme
      status_theme = helpers.ticket_status_theme(ticket.status)
      THEME_MAPPINGS.fetch(status_theme, THEME_MAPPINGS[:green])
    end

    def message
      I18n.t("support.ticket_status_banner.#{ticket.status}", default: I18n.t("support.ticket_status_banner.default"))
    end
  end
end
