class Core::CardComponent < ApplicationViewComponent
  option :variant, default: -> { :default }
  option :padding, default: -> { :md }
  option :glow, default: -> { false }
  option :classes, default: -> { "" }

  BASE_STYLES = "rounded transition-all duration-200 ease-out bg-highlight dark:hover:brightness-102 dark:focus-within:brightness-110 hover:shadow-md focus-within:shadow-md".freeze

  VARIANT_STYLES = {
    default: "border border-primary-500/20 dark:border-primary-500/20 dark:shadow-primary-500/80 hover:shadow-primary-500/20 dark:hover:shadow-primary-500/20 focus-within:shadow-primary-500/10 dark:focus-within:shadow-primary-500/20",
    primary: "border border-primary-500/45 dark:border-primary-400/20 shadow-primary-500/8 dark:shadow-primary-400/15 hover:shadow-primary-500/15 dark:hover:shadow-primary-400/25",
    secondary: "border border-secondary-500/15 dark:border-secondary-400/25 shadow-secondary-500/8 dark:shadow-secondary-400/15 hover:shadow-secondary-500/15 dark:hover:shadow-secondary-400/25",
  }.freeze

  PADDING_STYLES = {
    none: "p-0",
    xs: "p-2",
    sm: "p-4",
    md: "p-8",
    lg: "p-12",
    xl: "p-16"
  }.freeze

  GLOW_STYLE = "hover:shadow-[0_0_4px_rgba(139,69,244,0.15)] dark:hover:shadow-[0_0_10px_rgba(167,139,250,0.2)] focus-within:shadow-[0_0_10px_rgba(139,69,244,0.15)] dark:focus-within:shadow-[0_0_20px_rgba(167,139,250,0.2)]".freeze

  def html_classes
    class_names(BASE_STYLES, VARIANT_STYLES[variant], PADDING_STYLES[padding], (GLOW_STYLE if glow), classes)
  end
end
