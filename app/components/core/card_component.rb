class Core::CardComponent < ApplicationViewComponent
  option :variant, default: -> { :default }
  option :padding, default: -> { :md }
  option :glow, default: -> { false }
  option :classes, default: -> { "" }

  BASE_STYLES = "rounded-2xl transition-all duration-200 ease-out bg-highlight hover:-translate-y-1 hover:brightness-[1.02] dark:hover:brightness-102 focus-within:-translate-y-1 focus-within:brightness-[1.02] dark:focus-within:brightness-110".freeze

  VARIANT_STYLES = {
    default: "border border-primary-500/10 dark:border-primary-500/20 shadow-md shadow-primary-500/5 dark:shadow-primary-500/10 hover:shadow-lg hover:shadow-primary-500/10 dark:hover:shadow-primary-500/20 focus-within:shadow-xl focus-within:shadow-primary-500/10 dark:focus-within:shadow-primary-500/20",
    primary: "border border-primary-500/15 dark:border-primary-400/25 shadow-md shadow-primary-500/8 dark:shadow-primary-400/15 hover:shadow-lg hover:shadow-primary-500/15 dark:hover:shadow-primary-400/25",
    secondary: "border border-secondary-500/15 dark:border-secondary-400/25 shadow-md shadow-secondary-500/8 dark:shadow-secondary-400/15 hover:shadow-lg hover:shadow-secondary-500/15 dark:hover:shadow-secondary-400/25",
    minimal: "border border-gray-200/50 dark:border-gray-700/50 shadow-md shadow-gray-500/5 dark:shadow-black/20 hover:shadow-md hover:shadow-gray-500/10 dark:hover:shadow-black/30",
    glass: "border border-white/20 dark:border-white/10 shadow-md shadow-primary-500/5 dark:shadow-primary-400/10 hover:shadow-md hover:shadow-primary-500/10 dark:hover:shadow-primary-400/20"
  }.freeze

  PADDING_STYLES = {
    none: "p-0",
    xs: "p-2",
    sm: "p-4",
    md: "p-8",
    lg: "p-12",
    xl: "p-16"
  }.freeze

  GLOW_STYLE = "hover:shadow-[0_0_10px_rgba(139,69,244,0.15)] dark:hover:shadow-[0_0_20px_rgba(167,139,250,0.2)] focus-within:shadow-[0_0_10px_rgba(139,69,244,0.15)] dark:focus-within:shadow-[0_0_20px_rgba(167,139,250,0.2)]".freeze

  def html_classes
    class_names(BASE_STYLES, VARIANT_STYLES[variant], PADDING_STYLES[padding], (GLOW_STYLE if glow), classes)
  end
end
