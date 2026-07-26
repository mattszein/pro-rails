module Support::TicketsHelper
  def support_ticket_columns
    [
      Core::Table::Column.new(
        label: I18n.t("shared.labels.title"),
        sort_key: :title,
        filter: Core::Table::Filter.new(type: :text, param: :search, scope: :search_title)
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.category"),
        filter: Core::Table::Filter.new(
          type: :select,
          param: :category,
          options: -> { Support::Ticket.categories.keys.map { |c| [I18n.t("enums.ticket.category.#{c}"), c] } }
        )
      ),
      Core::Table::Column.new(label: I18n.t("shared.labels.description")),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.status"),
        sort_key: :status,
        filter: Core::Table::Filter.new(
          type: :select,
          param: :status,
          options: -> { Support::Ticket.statuses.keys.map { |s| [I18n.t("enums.ticket.status.#{s}"), s] } }
        )
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.created_on"),
        sort_key: :created_at
      ),
      Core::Table::Column.new(label: I18n.t("shared.common.actions"))
    ]
  end
end
