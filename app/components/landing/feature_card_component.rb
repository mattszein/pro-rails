class Landing::FeatureCardComponent < ApplicationViewComponent
  option :icon
  option :color
  option :i18n_key
  option :animated_type

  BORDER_HOVER = {
    blue: "hover:border-blue-200 dark:hover:border-blue-900/50",
    emerald: "hover:border-emerald-200 dark:hover:border-emerald-900/50",
    violet: "hover:border-violet-200 dark:hover:border-violet-900/50",
    rose: "hover:border-rose-200 dark:hover:border-rose-900/50",
    amber: "hover:border-amber-200 dark:hover:border-amber-900/50",
    cyan: "hover:border-cyan-200 dark:hover:border-cyan-900/50",
    orange: "hover:border-orange-200 dark:hover:border-orange-900/50",
    fuchsia: "hover:border-fuchsia-200 dark:hover:border-fuchsia-900/50"
  }.freeze

  BG_HOVER = {
    blue: "group-hover:bg-blue-50 dark:group-hover:bg-blue-900/20",
    emerald: "group-hover:bg-emerald-50 dark:group-hover:bg-emerald-900/20",
    violet: "group-hover:bg-violet-50 dark:group-hover:bg-violet-900/20",
    rose: "group-hover:bg-rose-50 dark:group-hover:bg-rose-900/20",
    amber: "group-hover:bg-amber-50 dark:group-hover:bg-amber-900/20",
    cyan: "group-hover:bg-cyan-50 dark:group-hover:bg-cyan-900/20",
    orange: "group-hover:bg-orange-50 dark:group-hover:bg-orange-900/20",
    fuchsia: "group-hover:bg-fuchsia-50 dark:group-hover:bg-fuchsia-900/20"
  }.freeze

  TITLE_HOVER = {
    blue: "group-hover:text-blue-700 dark:group-hover:text-blue-400",
    emerald: "group-hover:text-emerald-700 dark:group-hover:text-emerald-400",
    violet: "group-hover:text-violet-700 dark:group-hover:text-violet-400",
    rose: "group-hover:text-rose-700 dark:group-hover:text-rose-400",
    amber: "group-hover:text-amber-700 dark:group-hover:text-amber-400",
    cyan: "group-hover:text-cyan-700 dark:group-hover:text-cyan-400",
    orange: "group-hover:text-orange-700 dark:group-hover:text-orange-400",
    fuchsia: "group-hover:text-fuchsia-700 dark:group-hover:text-fuchsia-400"
  }.freeze

  ICON_TEXT = {
    blue: "text-blue-600 dark:text-blue-400",
    emerald: "text-emerald-600 dark:text-emerald-400",
    violet: "text-violet-600 dark:text-violet-400",
    rose: "text-rose-600 dark:text-rose-400",
    amber: "text-amber-600 dark:text-amber-400",
    cyan: "text-cyan-600 dark:text-cyan-400",
    orange: "text-orange-600 dark:text-orange-400",
    fuchsia: "text-fuchsia-600 dark:text-fuchsia-400"
  }.freeze

  def color_key
    color.to_sym
  end

  def card_classes
    class_names(
      "group relative bg-white dark:bg-[#1a1a1c] border border-slate-200 dark:border-[#2a2a2d]",
      "rounded-2xl p-6 transition-all duration-300 hover:shadow-xl hover:-translate-y-1 cursor-pointer",
      BORDER_HOVER[color_key]
    )
  end

  def icon_wrapper_classes
    class_names(
      "relative w-14 h-14 shrink-0 rounded-xl flex items-center justify-center",
      "bg-slate-50 dark:bg-[#2a2a2d] transition-colors duration-300",
      BG_HOVER[color_key],
      ICON_TEXT[color_key]
    )
  end

  def title_classes
    class_names(
      "text-lg font-semibold text-slate-800 dark:text-slate-100 transition-colors",
      TITLE_HOVER[color_key]
    )
  end
end
