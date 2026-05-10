module Adminit::TicketsHelper
  def ticket_columns
    [
      Core::Table::Column.new(
        label: I18n.t("shared.labels.title"),
        renderer: ->(ticket) { ticket.title },
        sort_key: :title,
        filter: Core::Table::Filter.new(type: :text, param: :search)
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.category"),
        renderer: ->(ticket) { I18n.t("enums.ticket.category.#{ticket.category}") }
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.status"),
        renderer: ->(ticket) {
          render(Core::BadgeComponent.new(label: I18n.t("enums.ticket.status.#{ticket.status}"),
            theme: ticket_status_theme(ticket.status)))
        },
        sort_key: :status,
        filter: Core::Table::Filter.new(
          type: :select,
          param: :status,
          options: -> { Support::Ticket.statuses.keys.map { |s| [I18n.t("enums.ticket.status.#{s}"), s] } }
        )
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.priority"),
        renderer: ->(ticket) { ticket.priority },
        sort_key: :priority
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.created"),
        renderer: ->(ticket) { ticket.created&.email }
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.assigned"),
        renderer: ->(ticket) { ticket.assigned&.email || "-" }
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.common.actions"),
        renderer: ->(ticket) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_ticket_path(ticket), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      )
    ]
  end
end
