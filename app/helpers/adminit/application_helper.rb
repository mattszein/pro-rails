module Adminit::ApplicationHelper
  def accounts_columns
    [
      Core::Table::Column.new(
        label: I18n.t("shared.labels.email"),
        renderer: ->(account) { account.email },
        sort_key: :email,
        filter: Core::Table::Filter.new(type: :text, param: :search)
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.status"),
        renderer: ->(account) {
          render(Core::BadgeComponent.new(label: I18n.t("enums.account.status.#{account.status}"), theme: account_status_theme(account.status)))
        },
        sort_key: :status,
        filter: Core::Table::Filter.new(
          type: :select,
          param: :status,
          options: -> { Account.statuses.keys.map { |s| [I18n.t("enums.account.status.#{s}"), s] } }
        )
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.role"),
        renderer: ->(account) { account.role&.name || "-" },
        filter: Core::Table::Filter.new(
          type: :select,
          param: :role_id,
          options: -> { Role.order(:name).map { |r| [r.name, r.id] } }
        )
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.common.actions"),
        renderer: ->(account) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_account_path(account), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      )
    ]
  end

  def role_member_columns(role)
    [
      Core::Table::Column.new(
        label: I18n.t("shared.labels.email"),
        renderer: ->(account) { account.email }
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.status"),
        renderer: ->(account) {
          render(Core::BadgeComponent.new(label: I18n.t("enums.account.status.#{account.status}"), theme: account_status_theme(account.status)))
        }
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.common.actions"),
        renderer: ->(account) {
          render(Core::LinkComponent.new(name: I18n.t("adminit.roles.remove_member"), url: account_adminit_role_path(role, account_id: account.id), style: :as_button, theme: :delete, size: :xs, html_options: {data: {turbo_method: :delete, turbo_confirm: I18n.t("shared.common.are_you_sure")}}))
        }
      )
    ]
  end

  def roles_columns
    [
      Core::Table::Column.new(
        label: I18n.t("shared.labels.name"),
        renderer: ->(role) { role.name }
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.common.actions"),
        renderer: ->(role) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_role_path(role), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      )
    ]
  end

  def announcement_columns
    [
      Core::Table::Column.new(
        label: I18n.t("shared.labels.reference"),
        renderer: ->(announcement) { announcement.reference },
        sort_key: :reference
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.status"),
        renderer: ->(announcement) {
          render(Core::BadgeComponent.new(label: I18n.t("enums.announcement.status.#{announcement.status}"),
            theme: announcement_status_theme(announcement.status)))
        },
        sort_key: :status,
        filter: Core::Table::Filter.new(
          type: :select,
          param: :status,
          options: -> { Announcement.statuses.keys.map { |s| [I18n.t("enums.announcement.status.#{s}"), s] } }
        )
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.author"),
        renderer: ->(announcement) { announcement.author.email }
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.labels.scheduled_at"),
        renderer: ->(announcement) { announcement.scheduled_at&.strftime("%Y-%m-%d %H:%M") || "-" },
        sort_key: :scheduled_at
      ),
      Core::Table::Column.new(
        label: I18n.t("shared.common.actions"),
        renderer: ->(announcement) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_announcement_path(announcement),
            style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      )
    ]
  end
end
