class Core::BoxComponent < ApplicationViewComponent
  option :variant, default: -> { :primary }
  option :padding, default: -> { :sm }
  option :rounded, default: -> { :sm }
  option :classes, default: -> { "" }

  VARIANT_STYLES = {
    primary: "bg-primary-50 dark:bg-primary-950 border border-primary-200 dark:border-primary-800 text-primary-900 dark:text-primary-100",
    secondary: "bg-secondary-50 dark:bg-secondary-950 border border-secondary-200 dark:border-secondary-800 text-secondary-900 dark:text-secondary-100",
    info: "bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-800 text-blue-900 dark:text-blue-100",
    success: "bg-emerald-50 dark:bg-emerald-950 border border-emerald-200 dark:border-emerald-800 text-emerald-900 dark:text-emerald-100",
    warning: "bg-amber-50 dark:bg-emerald-950 border border-amber-200 dark:border-amber-800 text-amber-900 dark:text-amber-100",
    error: "bg-red-50 dark:bg-red-950 border-red-200 dark:border-red-800 text-red-900 dark:text-red-100",
    neutral: "bg-slate-50 dark:bg-slate-950 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-gray-100"
  }.freeze

  PADDING_STYLES = {
    none: "p-0",
    xs: "p-2",
    sm: "p-4",
    md: "p-6",
    lg: "p-8"
  }.freeze

  ROUNDED_STYLES = {
    none: "rounded-none",
    sm: "rounded-sm",
    md: "rounded-md",
    lg: "rounded-lg",
    xl: "rounded-xl",
    "2xl": "rounded-2xl"
  }.freeze

  def html_classes
    class_names(VARIANT_STYLES[variant], PADDING_STYLES[padding], ROUNDED_STYLES[rounded], classes)
  end
end
