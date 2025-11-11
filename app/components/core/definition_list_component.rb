# app/components/core/definition_list_component.rb
class Core::DefinitionListComponent < ViewComponent::Base
  renders_many :items, Core::DefinitionListItemComponent

  attr_reader :variant, :gap, :layout, :classes

  VARIANTS = {
    default: "text-gray-900 dark:text-gray-100",
    info: "text-blue-900 dark:text-blue-100",
    success: "text-emerald-900 dark:text-emerald-100",
    warning: "text-amber-900 dark:text-amber-100",
    error: "text-red-900 dark:text-red-100"
  }.freeze

  GAP = {
    none: "gap-0",
    xs: "gap-1",
    sm: "gap-2",
    md: "gap-3",
    lg: "gap-4",
    xl: "gap-6"
  }.freeze

  LAYOUT = {
    stacked: "grid",
    inline: "grid grid-cols-1 sm:grid-cols-2",
    compact: "grid"
  }.freeze

  DEFAULT = {
    variant: :default,
    gap: :md,
    layout: :stacked,
    classes: ""
  }.freeze

  def initialize(options = {})
    options_merged = DEFAULT.merge(options)
    @variant = options_merged[:variant]
    @gap = options_merged[:gap]
    @layout = options_merged[:layout]
    @classes = options_merged[:classes]
  end

  def html_classes
    [
      LAYOUT[@layout],
      GAP[@gap],
      "grid-cols-[auto_1fr]", # This creates two columns: auto-width for dt, remaining space for dd
      VARIANTS[@variant],
      @classes
    ].compact.join(" ")
  end
end
