module Adminit::TicketsHelper
  # Returns an array of column definitions for the ticket table
  def ticket_columns
    [
      {
        label: I18n.t("views.labels.title"),
        renderer: ->(ticket) { ticket.title }
      },
      {
        label: I18n.t("views.labels.category"),
        renderer: ->(ticket) { I18n.t("enums.ticket.category.#{ticket.category}") }
      },
      {
        label: I18n.t("views.labels.status"),
        renderer: ->(ticket) do
          render(Core::BadgeComponent.new(label: I18n.t("enums.ticket.status.#{ticket.status}"),
            theme: ticket_status_theme(ticket.status)))
        end
      },
      {
        label: I18n.t("views.labels.priority"),
        renderer: ->(ticket) { ticket.priority }
      },
      {
        label: I18n.t("views.labels.created"),
        renderer: ->(ticket) { ticket.created&.email }
      },
      {
        label: I18n.t("views.labels.assigned"),
        renderer: ->(ticket) { ticket.assigned&.email || "-" }
      },
      {
        label: I18n.t("views.shared.actions"),
        renderer: ->(ticket) {
          render(Core::LinkComponent.new(name: I18n.t("views.shared.show"), url: adminit_ticket_path(ticket), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false}}))
        }
      }
    ]
  end
end
