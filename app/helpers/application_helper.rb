module ApplicationHelper
  include Pagy::Frontend

  def sidebar_links
    [
      {
        label: I18n.t("shared.navigation.home"),
        path: :dashboard_path,
        icon_name: "home"
      },
      {
        label: I18n.t("shared.navigation.settings"),
        path: :dashboard_path, # Replace with actual path
        icon_name: "settings"
      },
      {
        label: I18n.t("shared.common.logout"),
        path: rodauth.logout_path,
        icon_name: "logout",
        options: {data: {turbo_prefetch: "false", turbo_method: "post"}, method: :post}
      }
    ]
  end

  def icon(name, options = {})
    animated_type = options.delete(:animated_type)
    options[:title] ||= name.underscore.humanize
    options[:aria] = true
    options[:nocomment] = true
    # options[:variant] ||= :outline
    options[:class] = options.fetch(:classes, nil)
    path = options.fetch(:path, "icons/#{name}.svg")
    svg = inline_svg_tag(path, options)

    if animated_type
      content_tag(:div, svg,
        data: {
          controller: "animated-icon",
          animated_icon_type_value: animated_type
        })
    else
      svg
    end
  end

  def error_tag(content, options = {})
    content_tag(:span, content, class: "block mt-1 text-red-600 text-xs dark:text-red-400", id: options[:id])
  end

  TICKET_STATUS_THEME = {
    open: :green,
    in_progress: :yellow,
    finished: :red,
    reopen_requested: :orange,
    reopened: :green,
    closed: :red
  }
  def ticket_status_theme(status)
    TICKET_STATUS_THEME[status.to_sym]
  end

  def form_classes
    "w-full max-w-sm space-y-4"
  end

  ACCOUNT_STATUS_THEME = {unverified: :yellow, verified: :green, closed: :red}.freeze

  def account_status_theme(status)
    ACCOUNT_STATUS_THEME[status.to_sym]
  end

  def accounts_columns
    [
      {
        label: I18n.t("shared.labels.email"),
        renderer: ->(account) { account.email },
        sort_key: :email,
        filter: {type: :text, param: :search}
      },
      {
        label: I18n.t("shared.labels.status"),
        renderer: ->(account) {
          render(Core::BadgeComponent.new(label: I18n.t("enums.account.status.#{account.status}"), theme: account_status_theme(account.status)))
        },
        sort_key: :status,
        filter: {
          type: :select,
          param: :status,
          options: -> { Account.statuses.keys.map { |s| [I18n.t("enums.account.status.#{s}"), s] } }
        }
      },
      {
        label: I18n.t("shared.labels.role"),
        renderer: ->(account) { account.role&.name || "-" },
        filter: {
          type: :select,
          param: :role_id,
          options: -> { Role.order(:name).map { |r| [r.name, r.id] } }
        }
      },
      {
        label: I18n.t("shared.common.actions"),
        renderer: ->(account) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_account_path(account), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      }
    ]
  end

  def role_member_columns(role)
    [
      {
        label: I18n.t("shared.labels.email"),
        renderer: ->(account) { account.email }
      },
      {
        label: I18n.t("shared.labels.status"),
        renderer: ->(account) {
          render(Core::BadgeComponent.new(label: I18n.t("enums.account.status.#{account.status}"), theme: account_status_theme(account.status)))
        }
      },
      {
        label: I18n.t("shared.common.actions"),
        renderer: ->(account) {
          render(Core::LinkComponent.new(name: I18n.t("adminit.roles.remove_member"), url: account_adminit_role_path(role, account_id: account.id), style: :as_button, theme: :delete, size: :xs, html_options: {data: {turbo_method: :delete, turbo_confirm: I18n.t("shared.common.are_you_sure")}}))
        }
      }
    ]
  end

  def roles_columns
    [
      {
        label: I18n.t("shared.labels.name"),
        renderer: ->(role) { role.name }
      },
      {
        label: I18n.t("shared.common.actions"),
        renderer: ->(role) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_role_path(role), style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      }
    ]
  end

  ANNOUNCEMENT_STATUS_THEME = {draft: :yellow, scheduled: :orange, published: :green}
  def announcement_status_theme(status)
    ANNOUNCEMENT_STATUS_THEME[status.to_sym]
  end

  def announcement_columns
    [
      {
        label: I18n.t("shared.labels.reference"),
        renderer: ->(announcement) { announcement.reference },
        sort_key: :reference
      },
      {
        label: I18n.t("shared.labels.status"),
        renderer: ->(announcement) do
          render(Core::BadgeComponent.new(label: I18n.t("enums.announcement.status.#{announcement.status}"),
            theme: announcement_status_theme(announcement.status)))
        end,
        sort_key: :status,
        filter: {
          type: :select,
          param: :status,
          options: -> { Announcement.statuses.keys.map { |s| [I18n.t("enums.announcement.status.#{s}"), s] } }
        }
      },
      {
        label: I18n.t("shared.labels.author"),
        renderer: ->(announcement) { announcement.author.email }
      },
      {
        label: I18n.t("shared.labels.scheduled_at"),
        renderer: ->(announcement) { announcement.scheduled_at&.strftime("%Y-%m-%d %H:%M") || "-" },
        sort_key: :scheduled_at
      },
      {
        label: I18n.t("shared.common.actions"),
        renderer: ->(announcement) {
          render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_announcement_path(announcement),
            style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
        }
      }
    ]
  end
end
