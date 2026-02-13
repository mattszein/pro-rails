class Core::ToastComponent < ApplicationViewComponent
  option :title
  option :message, default: -> { nil }
  option :theme, default: -> { :info }
  option :icon, optional: true
  option :auto_dismiss, default: -> { true }

  THEMES = {
    primary: "border-l-primary-500",
    secondary: "border-l-secondary-500",
    success: "border-l-emerald-500",
    error: "border-l-rose-500",
    warning: "border-l-amber-500",
    info: "border-l-blue-500"
  }.freeze

  ICON_THEMES = {
    primary: "bg-primary-100 dark:bg-primary-500/20 text-primary-600 dark:text-primary-400",
    secondary: "bg-secondary-100 dark:bg-secondary-500/20 text-secondary-600 dark:text-secondary-400",
    success: "bg-emerald-100 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400",
    error: "bg-rose-100 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400",
    warning: "bg-amber-100 dark:bg-amber-500/20 text-amber-600 dark:text-amber-400",
    info: "bg-blue-100 dark:bg-blue-500/20 text-blue-600 dark:text-blue-400"
  }.freeze

  DEFAULT_ICONS = {
    primary: "toast/star",
    secondary: "toast/info",
    success: "toast/check",
    error: "toast/error",
    warning: "toast/warning",
    info: "toast/info"
  }.freeze

  def icon_name
    self.icon || DEFAULT_ICONS[theme]
  end

  def html_class
    class_names(
      "bg-white dark:bg-slate-800 dark:border dark:border-slate-700",
      "rounded-xl shadow-lg p-4 flex items-start gap-3 max-w-md border-l-4",
      THEMES[theme]
    )
  end

  def icon_container_class
    class_names(
      "flex-shrink-0 w-10 h-10 rounded-lg flex items-center justify-center",
      ICON_THEMES[theme]
    )
  end
end
