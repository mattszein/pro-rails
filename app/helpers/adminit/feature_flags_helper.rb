module Adminit
  module FeatureFlagsHelper
    def feature_flag_name(feature_flag)
      feature_flag.display_name
    end

    def feature_flag_description(feature_flag)
      I18n.t("feature_flags.flags.#{feature_flag.key}.description", default: nil)
    end

    def feature_flag_access_state(feature_flag)
      (feature_flag.audiences.any? || feature_flag.account_entries.allowed.any?) ? :open : :empty
    end

    # Column set drives both the query whitelist (Tableable) and the
    # rendered table — one array, used twice, so a sortable or filterable
    # field cannot exist without a rendered column.
    def feature_flag_columns
      [
        Core::Table::Column.new(
          label: t("shared.labels.name"),
          renderer: ->(flag) { link_to(feature_flag_name(flag), adminit_feature_flag_path(flag), data: {turbo_prefetch: false, turbo_frame: "_top"}) }
        ),
        Core::Table::Column.new(
          label: t("adminit.feature_flags.key"),
          renderer: ->(flag) { flag.key },
          sort_key: :key,
          filter: Core::Table::Filter.new(type: :text, param: :search, scope: :search_key)
        ),
        Core::Table::Column.new(
          label: t("adminit.feature_flags.access_state"),
          renderer: ->(flag) {
            state = feature_flag_access_state(flag)
            render(Core::BadgeComponent.new(
              label: t("adminit.feature_flags.access_states.#{state}"),
              theme: (state == :open) ? :green : :secondary
            ))
          },
          filter: Core::Table::Filter.new(
            type: :select, param: :access_state,
            options: -> { [[t("adminit.feature_flags.access_states.open"), "open"], [t("adminit.feature_flags.access_states.empty"), "empty"]] },
            scope: :by_access_state
          )
        ),
        Core::Table::Column.new(
          label: t("adminit.feature_flags.audiences"),
          renderer: ->(flag) { flag.audiences.size }
        ),
        Core::Table::Column.new(
          label: t("adminit.feature_flags.account_entries"),
          renderer: ->(flag) { flag.account_entries.size }
        )
      ]
    end

    def flag_account_entry_columns(feature_flag)
      [
        Core::Table::Column.new(
          label: t("shared.labels.email"),
          renderer: ->(entry) { entry.account.email }
        ),
        Core::Table::Column.new(
          label: t("adminit.feature_flags.access"),
          renderer: ->(entry) {
            render(Core::BadgeComponent.new(
              label: t("enums.feature_flag_account.access.#{entry.access}"),
              theme: entry.allowed? ? :green : :red
            ))
          }
        ),
        Core::Table::Column.new(
          label: t("shared.common.actions"),
          renderer: ->(entry) {
            render(Core::LinkComponent.new(
              name: t("shared.common.delete"),
              url: adminit_feature_flag_account_path(feature_flag, entry.account_id),
              style: :as_button, theme: :delete, size: :xs,
              html_options: {data: {turbo_method: :delete, turbo_confirm: t("shared.common.are_you_sure")}}
            ))
          }
        )
      ]
    end

    # Audiences offered to attach: active and not already attached (S19).
    def audience_search_scope(feature_flag)
      Audience.attachable(feature_flag)
    end
  end
end
