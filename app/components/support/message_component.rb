module Support
  class MessageComponent < ApplicationViewComponent
    option :message
    # Pre-loaded published articles to render as cards (the component never queries).
    option :articles, default: -> { [] }
    # Set (by the partial's data-only check) when the "This solved it" buttons may render.
    # Only `id` and `created_id` are read from it. The buttons are further gated client-side
    # to the requester via <turbo-show>, and hidden on all but the latest message by the
    # conversation Stimulus controller.
    option :resolution_ticket, default: -> {}

    def author_display_name
      message.ai? ? I18n.t("support.message.ai_name") : message.account.email
    end

    def is_support?
      message.human? && message.account.adminit_access?
    end

    def message_background
      if message.ai? || is_support?
        "bg-gradient-to-r from-secondary-50 to-secondary-100 border border-secondary-100 dark:from-secondary-950/30 dark:to-secondary-900/30 dark:border-secondary-800"
      else
        "bg-primary-50 border border-primary-100 dark:bg-primary-950/30 dark:border-primary-800"
      end
    end

    def author_badge
      if message.ai?
        render(Core::BadgeComponent.new(label: I18n.t("support.message.ai_badge"), theme: :violet, size: :xs))
      elsif is_support?
        render(Core::BadgeComponent.new(label: I18n.t("support.message.support_badge"), theme: :secondary, size: :xs))
      end
    end

    def show_articles?
      message.ai? && articles.any?
    end

    def show_resolution_actions?
      message.ai? && resolution_ticket.present? && message.metadata["resolution_proposed"].present?
    end
  end
end
