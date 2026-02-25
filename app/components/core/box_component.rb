class Core::BoxComponent < ApplicationViewComponent
  option :variant, default: -> { :info }
  option :padding, default: -> { :sm }
  option :rounded, default: -> { :xl }
  option :classes, default: -> { "" }

  VARIANT_STYLES = {
    info: "bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-950/30 dark:to-indigo-950/30 border border-blue-200 dark:border-blue-800 text-blue-900 dark:text-blue-100",
    success: "bg-gradient-to-r from-emerald-50 to-green-50 dark:from-emerald-950/30 dark:to-green-950/30 border border-emerald-200 dark:border-emerald-800 text-emerald-900 dark:text-emerald-100",
    warning: "bg-gradient-to-r from-amber-50 to-yellow-50 dark:from-amber-950/30 dark:to-yellow-950/30 border border-amber-200 dark:border-amber-800 text-amber-900 dark:text-amber-100",
    error: "bg-gradient-to-r from-red-50 to-rose-50 dark:from-red-950/30 dark:to-rose-950/30 border border-red-200 dark:border-red-800 text-red-900 dark:text-red-100",
    neutral: "bg-gradient-to-r from-gray-50 to-slate-50 dark:from-gray-900/30 dark:to-slate-900/30 border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-gray-100"
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
