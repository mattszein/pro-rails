module Adminit
  module Dashboard
    module Tickets
      # Minimal column set shared by the dashboard ticket tables: a title link
      # (breaks out of the lazy turbo frame) and a status badge.
      module TableColumns
        def columns
          [
            Core::Table::Column.new(
              label: I18n.t("shared.labels.title"),
              renderer: ->(ticket) {
                render Core::LinkComponent.new(
                  name: ticket.title,
                  url: helpers.adminit_ticket_path(ticket),
                  style: :link,
                  html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}
                )
              }
            ),
            Core::Table::Column.new(
              label: I18n.t("shared.labels.status"),
              renderer: ->(ticket) {
                render Core::BadgeComponent.new(
                  label: I18n.t("enums.ticket.status.#{ticket.status}"),
                  theme: helpers.ticket_status_theme(ticket.status),
                  size: :md
                )
              }
            )
          ]
        end
      end
    end
  end
end
