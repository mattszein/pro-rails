class Core::Form::ButtonComponent < ApplicationViewComponent
  attr_accessor :theme, :size

  THEME_MAPPINGS = {
    primary: {
      base: "bg-highlight border-primary-300 dark:border-primary-400",
      text_base: "text-primary-400 dark:text-primary-300",
      text_hover: "hover:text-primary-500 dark:hover:text-primary-200",
      hover: "hover:border-primary-400 dark:hover:border-primary-300 hover:shadow-primary-400/50 dark:hover:shadow-primary-300/50",
      focus: "focus:text-primary-500 dark:focus:text-primary-200 focus:border-primary-400 dark:focus:border-primary-300 focus:underline focus:outline-none",
      shimmer: "after:absolute after:inset-0 after:pointer-events-none after:bg-gradient-to-r after:from-transparent after:via-primary-800/[0.35] dark:after:via-white/15 after:to-transparent after:translate-x-[-100%] after:opacity-0 hover:after:translate-x-[100%] hover:after:opacity-100 focus:after:translate-x-[100%] focus:after:opacity-100 after:transition-all after:duration-300 after:ease-out"
    },
    secondary: {
      base: "bg-highlight border-secondary-300 dark:border-secondary-400",
      text_base: "text-secondary-400 dark:text-secondary-300",
      text_hover: "hover:text-secondary-500 dark:hover:text-secondary-200",
      hover: "hover:border-secondary-400 dark:hover:border-secondary-300 hover:shadow-secondary-400/50 dark:hover:shadow-secondary-300/50",
      focus: "focus:text-secondary-500 dark:focus:text-secondary-200 focus:border-secondary-400 dark:focus:border-secondary-300 focus:underline focus:outline-none",
      shimmer: "after:absolute after:inset-0 after:pointer-events-none after:bg-gradient-to-r after:from-transparent after:via-secondary-800/[0.35] dark:after:via-white/15 after:to-transparent after:translate-x-[-100%] after:opacity-0 hover:after:translate-x-[100%] hover:after:opacity-100 focus:after:translate-x-[100%] focus:after:opacity-100 after:transition-all after:duration-300 after:ease-out"
    },
    create: {
      base: "bg-highlight border-emerald-300 dark:border-emerald-400",
      text_base: "text-emerald-400 dark:text-emerald-300",
      text_hover: "hover:text-emerald-500 dark:hover:text-emerald-200",
      hover: "hover:border-emerald-400 dark:hover:border-emerald-300 hover:shadow-emerald-400/50 dark:hover:shadow-emerald-300/50",
      focus: "focus:text-emerald-500 dark:focus:text-emerald-200 focus:border-emerald-400 dark:focus:border-emerald-300 focus:underline focus:outline-none",
      shimmer: "after:absolute after:inset-0 after:pointer-events-none after:bg-gradient-to-r after:from-transparent after:via-emerald-800/[0.35] dark:after:via-white/15 after:to-transparent after:translate-x-[-100%] after:opacity-0 hover:after:translate-x-[100%] hover:after:opacity-100 focus:after:translate-x-[100%] focus:after:opacity-100 after:transition-all after:duration-300 after:ease-out"
    },
    edit: {
      base: "bg-highlight border-blue-300 dark:border-blue-400",
      text_base: "text-blue-400 dark:text-blue-300",
      text_hover: "hover:text-blue-500 dark:hover:text-blue-200",
      hover: "hover:border-blue-400 dark:hover:border-blue-300 hover:shadow-blue-400/50 dark:hover:shadow-blue-300/50",
      focus: "focus:text-blue-500 dark:focus:text-blue-200 focus:border-blue-400 dark:focus:border-blue-300 focus:underline focus:outline-none",
      shimmer: "after:absolute after:inset-0 after:pointer-events-none after:bg-gradient-to-r after:from-transparent after:via-blue-800/[0.35] dark:after:via-white/15 after:to-transparent after:translate-x-[-100%] after:opacity-0 hover:after:translate-x-[100%] hover:after:opacity-100 focus:after:translate-x-[100%] focus:after:opacity-100 after:transition-all after:duration-300 after:ease-out"
    },
    delete: {
      base: "bg-highlight border-red-300 dark:border-red-400",
      text_base: "text-red-400 dark:text-red-300",
      text_hover: "hover:text-red-500 dark:hover:text-red-200",
      hover: "hover:border-red-400 dark:hover:border-red-300 hover:shadow-red-400/50 dark:hover:shadow-red-300/50",
      focus: "focus:text-red-500 dark:focus:text-red-200 focus:border-red-400 dark:focus:border-red-300 focus:underline focus:outline-none",
      shimmer: "after:absolute after:inset-0 after:pointer-events-none after:bg-gradient-to-r after:from-transparent after:via-red-800/[0.35] dark:after:via-white/15 after:to-transparent after:translate-x-[-100%] after:opacity-0 hover:after:translate-x-[100%] hover:after:opacity-100 focus:after:translate-x-[100%] focus:after:opacity-100 after:transition-all after:duration-300 after:ease-out"
    },
    show: {
      base: "bg-highlight border-indigo-300 dark:border-indigo-400",
      text_base: "text-indigo-400 dark:text-indigo-300",
      text_hover: "hover:text-indigo-500 dark:hover:text-indigo-200",
      hover: "hover:border-indigo-400 dark:hover:border-indigo-300 hover:shadow-indigo-400/50 dark:hover:shadow-indigo-300/50",
      focus: "focus:text-indigo-500 dark:focus:text-indigo-200 focus:border-indigo-400 dark:focus:border-indigo-300 focus:underline focus:outline-none",
      shimmer: "after:absolute after:inset-0 after:pointer-events-none after:bg-gradient-to-r after:from-transparent after:via-indigo-800/[0.35] dark:after:via-white/15 after:to-transparent after:translate-x-[-100%] after:opacity-0 hover:after:translate-x-[100%] hover:after:opacity-100 focus:after:translate-x-[100%] focus:after:opacity-100 after:transition-all after:duration-300 after:ease-out"
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
    @form = form
    default = {theme: :primary, size: :md, fullw: false}
    style_merged = default.merge(style)
    @value = value
    @theme = style_merged[:theme]
    @fullw = style_merged[:fullw]
    @size = style_merged[:size]
    @options = options
    super()
  end

  def call
    helpers.button_tag(@value, @options.merge(class: html_class))
  end

  def html_class
    theme_config = THEME_MAPPINGS[@theme]
    class_names(
      "relative overflow-hidden rounded border isolate", 
      "font-medium text-center font-semibold inline-block",
      "dark:hover:bg-default dark:focus:bg-default hover:shadow-md", 
      "cursor-pointer select-none transition-all",
      theme_config[:base],
      theme_config[:text_base],
      theme_config[:text_hover],
      theme_config[:hover],
      theme_config[:focus],
      theme_config[:shimmer],
      SIZE_MAPPINGS[@size],
      @fullw ? "w-full" : ""
    )
  end
end
