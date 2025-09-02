class Core::Form::ButtonComponent < ViewComponent::Form::ButtonComponent
  attr_accessor :theme, :size

  THEME_MAPPINGS = {
    primary: {
      base: "bg-highlight border-violet-500/30",
      text_base: "text-violet-500 dark:text-violet-300",
      text_hover: "hover:text-violet-700 dark:hover:text-violet-200",
      hover_border: "hover:border-violet-500/60 dark:hover:border-violet-300/50",
      focus: "focus:text-violet-700 dark:focus:text-violet-200 focus:border-violet-500/60 dark:focus:border-violet-300/50 focus:ring-violet-500/30 dark:focus:ring-violet-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-violet-800/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-300 after:ease-out"
    },
    secondary: {
      base: "bg-highlight border-pink-500/30",
      text_base: "text-pink-500 dark:text-pink-300",
      text_hover: "hover:text-pink-700 dark:hover:text-pink-200",
      hover_border: "hover:border-pink-500/60 dark:hover:border-pink-300/50",
      focus: "focus:text-pink-700 dark:focus:text-pink-200 focus:border-pink-500/60 dark:focus:border-pink-300/50 focus:ring-pink-500/30 dark:focus:ring-pink-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-pink-800/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-300 after:ease-out"
    },
    create: {
      base: "bg-highlight border-emerald-500/30",
      text_base: "text-emerald-500 dark:text-emerald-300",
      text_hover: "hover:text-emerald-700 dark:hover:text-emerald-200",
      hover_border: "hover:border-emerald-500/60 dark:hover:border-emerald-300/50",
      focus: "focus:text-emerald-700 dark:focus:text-emerald-200 focus:border-emerald-500/60 dark:focus:border-emerald-300/50 focus:ring-emerald-500/30 dark:focus:ring-emerald-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-emerald-800/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-300 after:ease-out"
    },
    edit: {
      base: "bg-highlight border-blue-500/30",
      text_base: "text-blue-500 dark:text-blue-300",
      text_hover: "hover:text-blue-700 dark:hover:text-blue-200",
      hover_border: "hover:border-blue-500/60 dark:hover:border-blue-300/50",
      focus: "focus:text-blue-700 dark:focus:text-blue-200 focus:border-blue-500/60 dark:focus:border-blue-300/50 focus:ring-blue-500/30 dark:focus:ring-blue-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-blue-800/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-300 after:ease-out"
    },
    delete: {
      base: "bg-highlight border-red-500/30",
      text_base: "text-red-500 dark:text-red-300",
      text_hover: "hover:text-red-700 dark:hover:text-red-200",
      hover_border: "hover:border-red-500/60 dark:hover:border-red-300/50",
      focus: "focus:text-red-700 dark:focus:text-red-200 focus:border-red-500/60 dark:focus:border-red-300/50 focus:ring-red-500/30 dark:focus:ring-red-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-red-800/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-300 after:ease-out"
    },
    show: {
      base: "bg-highlight border-indigo-500/30",
      text_base: "text-indigo-500 dark:text-indigo-300",
      text_hover: "hover:text-indigo-700 dark:hover:text-indigo-200",
      hover_border: "hover:border-indigo-500/60 dark:hover:border-indigo-300/50",
      focus: "focus:text-indigo-700 dark:focus:text-indigo-200 focus:border-indigo-500/60 dark:focus:border-indigo-300/50 focus:ring-indigo-500/30 dark:focus:ring-indigo-400/40",
      shimmer: "after:absolute after:inset-0 after:rounded-lg after:pointer-events-none " \
        "after:bg-gradient-to-r after:from-transparent " \
        "after:via-indigo-800/[0.15] dark:after:via-white/15 after:to-transparent " \
        "after:translate-x-[-100%] after:opacity-0 " \
        "hover:after:translate-x-[100%] hover:after:opacity-100 " \
        "after:transition-all after:duration-300 after:ease-out"
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
      "relative overflow-hidden rounded-lg border isolate",
      "font-medium text-center font-semibold inline-block",
      "focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-offset-transparent",
      "transform transition-all duration-300 ease-out",
      "hover:scale-[1.00] hover:shadow-md active:scale-[0.99]",
      "cursor-pointer select-none",
      theme_config[:base],
      theme_config[:text_base],
      theme_config[:text_hover],
      theme_config[:hover_border],
      theme_config[:focus],
      theme_config[:shimmer],
      SIZE_MAPPINGS[@size],
      @fullw ? "w-full" : ""
    )
  end
end
