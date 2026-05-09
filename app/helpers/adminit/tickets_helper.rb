module Adminit::TicketsHelper
  def ticket_columns
    [
      {
        label: I18n.t("shared.labels.title"),
        renderer: ->(ticket) { ticket.title },
        sort_key: :title,
        filter: {type: :text, param: :search}
      },
      {
        label: I18n.t("shared.labels.category"),
        renderer: ->(ticket) { I18n.t("enums.ticket.category.#{ticket.category}") }
      },
      {
        label: I18n.t("shared.labels.status"),
        renderer: ->(ticket) do
          render(Core::BadgeComponent.new(label: I18n.t("enums.ticket.status.#{ticket.status}"),
            theme: ticket_status_theme(ticket.status)))
        end,
        sort_key: :status,
        filter: {
          type: :select,
          param: :status,
          options: -> { Support::Ticket.statuses.keys.map { |s| [I18n.t("enums.ticket.status.#{s}"), s] } }
        }
      },
      {
        label: I18n.t("shared.labels.priority"),
        renderer: ->(ticket) { ticket.priority },
        sort_key: :priority
      },
      {
        label: I18n.t("shared.labels.created"),
        renderer: ->(ticket) { ticket.created&.email }
      },
      {
        label: I18n.t("shared.labels.assigned"),
        renderer: ->(ticket) { ticket.assigned&.email || "-" }
      },
      {
        label: I18n.t("shared.common.actions"),
        renderer: ->(ticket) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_ticket_path(ticket), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      }
    ]
  end
end
