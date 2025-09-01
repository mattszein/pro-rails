# frozen_string_literal: true

class Core::Form::ButtonComponent < ViewComponent::Form::ButtonComponent
  attr_accessor :theme, :size

  THEME_MAPPINGS = {
    primary: {
      base: "bg-white dark:bg-white/[0.02] border-violet-500/20 text-violet-600 dark:text-violet-300",
      hover_bg: "hover:bg-violet-500/[0.04] dark:hover:bg-violet-400/[0.12]",
      hover_border: "hover:border-violet-400/60 dark:hover:border-violet-300/50",
      focus: "focus:ring-violet-500/30 dark:focus:ring-violet-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-violet-400/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-500 after:ease-out",
      text_glow: "hover:text-violet-500 dark:hover:text-violet-200"
    },
    secondary: {
      base: "bg-white dark:bg-white/[0.02] border-pink-500/20 text-pink-600 dark:text-pink-300",
      hover_bg: "hover:bg-pink-500/[0.04] dark:hover:bg-pink-400/[0.12]",
      hover_border: "hover:border-pink-400/60 dark:hover:border-pink-300/50",
      focus: "focus:ring-pink-500/30 dark:focus:ring-pink-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-pink-400/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-500 after:ease-out",
      text_glow: "hover:text-pink-500 dark:hover:text-pink-200"
    },
    create: {
      base: "bg-white/5 dark:bg-white/[0.02] border-emerald-500/20 text-emerald-600 dark:text-emerald-300",
      hover_bg: "hover:bg-emerald-500/[0.04] dark:hover:bg-emerald-400/[0.12]",
      hover_border: "hover:border-emerald-400/60 dark:hover:border-emerald-300/50",
      focus: "focus:ring-emerald-500/30 dark:focus:ring-emerald-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-emerald-400/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-500 after:ease-out",
      text_glow: "hover:text-emerald-500 dark:hover:text-emerald-200"
    },
    edit: {
      base: "bg-white/5 dark:bg-white/[0.02] border-blue-500/20 text-blue-600 dark:text-blue-300",
      hover_bg: "hover:bg-blue-500/[0.04] dark:hover:bg-blue-400/[0.12]",
      hover_border: "hover:border-blue-400/60 dark:hover:border-blue-300/50",
      focus: "focus:ring-blue-500/30 dark:focus:ring-blue-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-blue-400/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-500 after:ease-out",
      text_glow: "hover:text-blue-500 dark:hover:text-blue-200"
    },
    delete: {
      base: "bg-white/5 dark:bg-white/[0.02] border-red-500/20 text-red-600 dark:text-red-300",
      hover_bg: "hover:bg-red-500/[0.04] dark:hover:bg-red-400/[0.12]",
      hover_border: "hover:border-red-400/60 dark:hover:border-red-300/50",
      focus: "focus:ring-red-500/30 dark:focus:ring-red-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-red-400/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-500 after:ease-out",
      text_glow: "hover:text-red-500 dark:hover:text-red-200"
    },
    show: {
      base: "bg-white/5 dark:bg-white/[0.02] border-indigo-500/20 text-indigo-600 dark:text-indigo-300",
      hover_bg: "hover:bg-indigo-500/[0.04] dark:hover:bg-indigo-400/[0.12]",
      hover_border: "hover:border-indigo-400/60 dark:hover:border-indigo-300/50",
      focus: "focus:ring-indigo-500/30 dark:focus:ring-indigo-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-indigo-400/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-500 after:ease-out",
      text_glow: "hover:text-indigo-500 dark:hover:text-indigo-200"
    }
  }

  SIZE_MAPPINGS = {
    none: "",
    xs: "px-3 py-1.5 text-xs",
    sm: "px-4 py-2 text-sm",
    md: "px-5 py-2.5 text-base",
    lg: "px-6 py-3 text-lg",
    xlg: "px-8 py-3.5 text-xl",
    giant: "px-10 py-4 text-2xl"
  }.freeze

  def initialize(form, value, style = {}, options = {})
    default = {theme: :primary, size: :md, fullw: false}
    style_merged = default.merge(style)
    @value = value
    @theme = style_merged[:theme]
    @fullw = style_merged[:fullw]
    @size = style_merged[:size]
    super(form, value, options)
  end

  def html_class
    theme_config = THEME_MAPPINGS[@theme]
    class_names(
      "relative overflow-hidden rounded-lg border backdrop-blur-sm isolate",
      "font-medium text-center font-semibold inline-block",
      "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-transparent",
      "transform transition-all duration-300 ease-out",
      "hover:scale-[1.00] hover:shadow-md active:scale-[0.99]",
      "cursor-pointer select-none",
      theme_config[:base],
      theme_config[:hover_bg],
      theme_config[:hover_border],
      theme_config[:focus],
      theme_config[:shimmer],
      theme_config[:text_glow],
      SIZE_MAPPINGS[@size],
      @fullw ? "w-full" : ""
    )
  end
end
