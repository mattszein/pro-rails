module Support
  class TicketStatusBannerComponent < ApplicationViewComponent
    option :ticket

    def render?
      !ticket.messageable?
    end

    BANNER_CONFIG = {
      "finished" => {
        wrapper: "bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 text-blue-800 dark:text-blue-300",
        icon: "info",
        message: "This ticket is marked as finished."
      },
      "reopen_requested" => {
        wrapper: "bg-orange-50 dark:bg-orange-900/20 border-orange-200 dark:border-orange-800 text-orange-800 dark:text-orange-300",
        icon: "info",
        message: "Reopen request pending approval. You will be able to message once an admin accepts it."
      },
      "closed" => {
        wrapper: "bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-800 dark:text-red-300",
        icon: "lock",
        message: "This ticket is permanently closed."
      }
    }.freeze

    DEFAULT_CONFIG = {
      wrapper: "bg-slate-50 dark:bg-slate-900/20 border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400",
      icon: "clock",
      message: "Waiting for an admin to take this ticket. You can send messages once the ticket is in progress."
    }.freeze

    def banner_config
      BANNER_CONFIG.fetch(ticket.status, DEFAULT_CONFIG)
    end
  end
end
