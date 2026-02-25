module Adminit::TicketsHelper
  # Returns an array of column definitions for the ticket table
  def ticket_columns
    [
      {
        label: "Title",
        renderer: ->(ticket) { ticket.title }
      },
      {
        label: "Category",
        renderer: ->(ticket) { ticket.category.humanize }
      },
      {
        label: "Status",
        renderer: ->(ticket) do
          render(Core::BadgeComponent.new(label: ticket.status.humanize,
            theme: ticket_status_theme(ticket.status)))
        end
      },
      {
        label: "Priority",
        renderer: ->(ticket) { ticket.priority }
      },
      {
        label: "Created",
        renderer: ->(ticket) { ticket.created&.email }
      },
      {
        label: "Assigned",
        renderer: ->(ticket) { ticket.assigned&.email || "-" }
      },
      {
        label: "Actions",
        renderer: ->(ticket) {
          render(Core::LinkComponent.new(name: "Show", url: adminit_ticket_path(ticket), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false}}))
        }
      }
    ]
  end
end
