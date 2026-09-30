class Core::LogoComponent < ApplicationViewComponent
  # Brand SVGs are inlined so `currentColor` and `--pr-accent` reach inside them.
  # The accent follows the active theme's primary color.
  MARK = "brand/pro-rails-mark-small.svg".freeze
  LOCKUP = "brand/pro-rails-horizontal-themeable.svg".freeze

  option :variant, default: -> { :responsive }
  option :html_class, default: -> { "" }

  def mark_class
    (variant == :responsive) ? "h-8 w-auto text-primary-500 sm:hidden" : "h-8 w-auto text-primary-500"
  end

  def lockup_class
    (variant == :responsive) ? "hidden h-7 w-auto sm:block" : "h-7 w-auto"
  end

  def show_mark? = variant != :lockup

  def show_lockup? = variant != :mark

  erb_template <<~ERB
    <span class="inline-flex items-center text-gray-900 dark:text-gray-100 [--pr-accent:var(--color-primary-500)] <%= html_class %>">
      <% if show_mark? %><%= helpers.inline_svg_tag(MARK, class: mark_class) %><% end %>
      <% if show_lockup? %><%= helpers.inline_svg_tag(LOCKUP, class: lockup_class) %><% end %>
    </span>
  ERB
end
