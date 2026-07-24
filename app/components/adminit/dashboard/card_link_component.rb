module Adminit
  module Dashboard
    class CardLinkComponent < ApplicationViewComponent
      option :label
      option :path
      option :icon_name
      option :animated_type, default: -> {}

      ANIMATED_ICON_ACTION = "mouseenter->animated-icon#start mouseleave->animated-icon#stop focusin->animated-icon#start focusout->animated-icon#stop"

      def link_classes
        "flex items-center rounded-xs border border-zinc-800 text-left transition-all duration-150 group hover:border-primary-400"
      end

      def icon_classes
        "h-8 text-gray-500 dark:text-gray-400 group-hover:text-secondary-500 dark:group-hover:text-secondary-500 group-focus/link:text-secondary-500 dark:group-focus/link:text-secondary-500"
      end

      def link_html_options
        merged = {class: link_classes}
        return merged unless animated_type

        existing_data = merged[:data] || {}
        merged[:data] = existing_data.merge(
          controller: join_tokens(existing_data[:controller], "animated-icon"),
          animated_icon_type_value: animated_type,
          action: join_tokens(existing_data[:action], ANIMATED_ICON_ACTION)
        )
        merged
      end

      private

      def join_tokens(existing, added)
        [existing, added].compact.reject(&:empty?).join(" ")
      end
    end
  end
end
