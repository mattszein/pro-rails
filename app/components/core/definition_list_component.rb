# app/components/core/definition_list_component.rb
class Core::DefinitionListComponent < ApplicationViewComponent
  renders_many :items, Core::DefinitionListItemComponent

  option :variant, default: -> { :default }
  option :gap, default: -> { :md }
  option :layout, default: -> { :stacked }
  option :classes, default: -> { "" }

  VARIANT_STYLES = {
    default: "text-gray-900 dark:text-gray-100",
    info: "text-blue-900 dark:text-blue-100",
    success: "text-emerald-900 dark:text-emerald-100",
    warning: "text-amber-900 dark:text-amber-100",
    error: "text-red-900 dark:text-red-100"
  }.freeze

  GAP_STYLES = {
    none: "gap-0",
    xs: "gap-1",
    sm: "gap-2",
    md: "gap-3",
    lg: "gap-4",
    xl: "gap-6"
  }.freeze

  LAYOUT_STYLES = {
    stacked: "grid",
    inline: "grid grid-cols-1 sm:grid-cols-2",
    compact: "grid"
  }.freeze

  def html_classes
    class_names(LAYOUT_STYLES[layout], GAP_STYLES[gap], "grid-cols-[auto_1fr]", VARIANT_STYLES[variant], classes)
  end
end
