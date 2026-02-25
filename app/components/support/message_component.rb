module Support
  class MessageComponent < ApplicationViewComponent
    option :message

    def author_display_name
      message.account.email
    end

    def is_support?
      message.account.adminit_access?
    end

    def message_background
      if is_support?
        "bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-100 dark:from-emerald-950/30 dark:to-teal-950/30 dark:border-emerald-800"
      else
        "bg-slate-100 dark:bg-slate-800"
      end
    end

    def author_badge
      return nil unless is_support?

      content_tag(:span, "Support",
        class: "text-xs bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200 px-2 py-0.5 rounded-full")
    end
  end
end
