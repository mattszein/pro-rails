module Adminit
  module AudiencesHelper
    def audience_columns
      [
        Core::Table::Column.new(
          label: t("shared.labels.name"),
          renderer: ->(audience) { link_to(audience.name, adminit_audience_path(audience), data: {turbo_prefetch: false, turbo_frame: "_top"}) },
          sort_key: :name,
          filter: Core::Table::Filter.new(type: :text, param: :search, scope: :search_name)
        ),
        Core::Table::Column.new(
          label: t("adminit.audiences.state"),
          renderer: ->(audience) {
            render(Core::BadgeComponent.new(
              label: t("adminit.audiences.states.#{audience.archived? ? :archived : :active}"),
              theme: audience.archived? ? :secondary : :green
            ))
          }
        ),
        Core::Table::Column.new(
          label: t("adminit.audiences.flags_attached"),
          renderer: ->(audience) { audience.flag_usage_count.to_i }
        ),
        Core::Table::Column.new(
          label: t("shared.common.actions"),
          renderer: ->(audience) {
            if audience.archived?
              render(Core::LinkComponent.new(
                name: t("adminit.audiences.unarchive"),
                url: unarchive_adminit_audience_path(audience),
                style: :as_button, theme: :edit, size: :xs,
                html_options: {data: {turbo_method: :patch, turbo_frame: "_top"}}
              ))
            else
              render(Core::LinkComponent.new(
                name: t("adminit.audiences.archive"),
                url: archive_adminit_audience_path(audience),
                style: :as_button, theme: :delete, size: :xs,
                html_options: {data: {turbo_method: :patch, turbo_confirm: t("shared.common.are_you_sure"), turbo_frame: "_top"}}
              ))
            end
          }
        )
      ]
    end

    # One readable line per stored condition.
    def audience_condition_summary(audience)
      audience.audience_conditions.filter_map { |condition| condition_summary_line(condition) }.join(", ")
    end

    private

    def condition_summary_line(audience_condition)
      condition = audience_condition.condition
      return nil unless condition

      label = t("audience_conditions.#{condition.key}.label")
      "#{label}: #{condition_summary_value(audience_condition, condition)}"
    end

    def condition_summary_value(audience_condition, condition)
      value = audience_condition.value
      case condition.type
      when :boolean
        t("audience_conditions.#{condition.key}.values.#{value}")
      when :affirmative
        t("audience_conditions.#{condition.key}.values.true")
      when :id_list
        audience_condition.referenced_records.pluck(:name).join(", ").presence || "-"
      when :duration
        amount = value["amount"] || value[:amount]
        unit = value["unit"] || value[:unit]
        "#{amount} #{t("audience_conditions.#{condition.key}.units.#{unit}", default: unit)}"
      end
    end
  end
end
