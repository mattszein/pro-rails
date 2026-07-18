module Adminit
  module Dashboard
    module Roles
      class GeneralWidgetComponent < ApplicationViewComponent
        option :account

        def roles
          @roles ||= Role.order(:name)
            .includes(:permissions)
            .select("roles.*, (SELECT COUNT(*) FROM accounts WHERE accounts.role_id = roles.id) AS accounts_count")
        end

        def columns
          [
            {
              label: I18n.t("shared.labels.name"),
              renderer: ->(role) {
                render Core::LinkComponent.new(
                  name: role.name,
                  url: helpers.adminit_role_path(role),
                  style: :link,
                  html_options: {data: {turbo_frame: "_top", turbo_prefetch: false}}
                )
              }
            },
            {
              label: I18n.t("shared.labels.accounts"),
              renderer: ->(role) { role.accounts_count }
            },
            {
              label: I18n.t("adminit.navigation.permissions"),
              renderer: ->(role) { permission_labels(role) }
            }
          ]
        end

        private

        def permission_labels(role)
          return I18n.t("adminit.dashboard_widgets.roles.no_permissions") if role.permissions.empty?

          role.permissions.map do |p|
            I18n.t("adminit.navigation.#{p.resource.pluralize}", default: p.resource.humanize)
          end.join(", ")
        end
      end
    end
  end
end
