module Adminit
  module AiPlaybooksHelper
    def ai_playbook_mode_label(mode)
      I18n.t("enums.support_ai_playbook.mode.#{mode}")
    end

    def ai_playbook_mode_options
      Support::AiPlaybook.modes.keys.map { |mode| [ai_playbook_mode_label(mode), mode] }
    end

    def ai_playbook_category_options
      Support::Ticket::CATEGORIES.keys.map { |key| [I18n.t("enums.ticket.category.#{key}"), key.to_s] }
    end

    def ai_playbook_priority_options
      Support::AiPlaybook::PRIORITY_RANGE.to_a
    end

    def ai_playbook_audience_options
      Audience.active.order(:name).map { |audience| [audience.name, audience.id] }
    end

    # Registry capabilities split into the form's two groups, in declaration order.
    def ai_playbook_capability_groups
      grouped = SupportAi::Capabilities::Registry.all.group_by(&:kind)
      {read: grouped[:read] || [], action: grouped[:action] || []}
    end

    def ai_playbook_capability_label(key) = I18n.t("support_ai.capabilities.#{key}.label")

    def ai_playbook_capability_description(key) = I18n.t("support_ai.capabilities.#{key}.description")

    def ai_playbook_categories_label(playbook)
      return I18n.t("adminit.ai_playbooks.any") if playbook.category_keys.empty?

      playbook.category_keys.map { |key| I18n.t("enums.ticket.category.#{key}") }.join(", ")
    end

    def ai_playbook_priority_label(playbook)
      min = playbook.min_priority
      max = playbook.max_priority
      return I18n.t("adminit.ai_playbooks.any") if min.nil? && max.nil?

      "#{min || 1}-#{max || 5}"
    end

    def ai_playbook_columns
      [
        Core::Table::Column.new(
          label: I18n.t("shared.labels.name"),
          renderer: ->(playbook) {
            badge = if playbook.is_default?
              render(Core::BadgeComponent.new(label: I18n.t("adminit.ai_playbooks.default_badge"), theme: :primary, size: :xs, classes: "ms-2"))
            end
            safe_join([playbook.name, badge].compact)
          }
        ),
        Core::Table::Column.new(
          label: I18n.t("adminit.ai_playbooks.mode"),
          renderer: ->(playbook) { ai_playbook_mode_label(playbook.mode) }
        ),
        Core::Table::Column.new(
          label: I18n.t("adminit.ai_playbooks.categories"),
          renderer: ->(playbook) { ai_playbook_categories_label(playbook) }
        ),
        Core::Table::Column.new(
          label: I18n.t("adminit.ai_playbooks.priority_range"),
          renderer: ->(playbook) { ai_playbook_priority_label(playbook) }
        ),
        Core::Table::Column.new(
          label: I18n.t("adminit.ai_playbooks.audience"),
          renderer: ->(playbook) { playbook.audience&.name || I18n.t("adminit.ai_playbooks.any") }
        ),
        Core::Table::Column.new(
          label: I18n.t("adminit.ai_playbooks.enabled"),
          renderer: ->(playbook) {
            render(Core::BadgeComponent.new(
              label: I18n.t(playbook.enabled? ? "adminit.ai_playbooks.enabled_on" : "adminit.ai_playbooks.enabled_off"),
              theme: playbook.enabled? ? :green : :secondary
            ))
          }
        ),
        Core::Table::Column.new(
          label: I18n.t("shared.common.actions"),
          renderer: ->(playbook) { ai_playbook_actions(playbook) }
        )
      ]
    end

    def ai_playbook_actions(playbook)
      post = {data: {turbo_method: :post, turbo_prefetch: false, turbo_frame: "_top"}}
      links = []
      unless playbook.is_default?
        links << ai_playbook_link(I18n.t("adminit.ai_playbooks.move_up"), move_up_adminit_ai_playbook_path(playbook), :show, post)
        links << ai_playbook_link(I18n.t("adminit.ai_playbooks.move_down"), move_down_adminit_ai_playbook_path(playbook), :show, post)
      end
      links << ai_playbook_link(
        I18n.t(playbook.enabled? ? "adminit.ai_playbooks.toggle_disable" : "adminit.ai_playbooks.toggle_enable"),
        toggle_adminit_ai_playbook_path(playbook), :edit, post
      )
      links << ai_playbook_link(I18n.t("shared.common.edit"), edit_adminit_ai_playbook_path(playbook), :edit, {data: {turbo_frame: "modal"}})
      unless playbook.is_default?
        links << ai_playbook_link(I18n.t("shared.common.delete"), adminit_ai_playbook_path(playbook), :delete,
          {data: {turbo_method: :delete, turbo_confirm: I18n.t("shared.common.are_you_sure"), turbo_frame: "_top"}})
      end
      tag.div(safe_join(links), class: "flex flex-wrap gap-1")
    end

    private

    def ai_playbook_link(name, url, theme, html_options)
      render(Core::LinkComponent.new(name: name, url: url, style: :as_button, theme: theme, size: :xs, html_options: html_options))
    end
  end
end
