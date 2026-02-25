# app/components/core/definition_list_item_component.rb
class Core::DefinitionListItemComponent < ApplicationViewComponent
  option :term
  option :size, default: -> { :sm }
  option :term_gap, default: -> { :sm }

  SIZE_STYLES = {
    xs: "text-xs",
    sm: "text-sm",
    base: "text-base",
    lg: "text-lg"
  }.freeze

  TERM_GAP_STYLES = {
    none: "pr-0",
    xs: "pr-2",
    sm: "pr-3",
    md: "pr-4",
    lg: "pr-6"
  }.freeze

  def term_classes
    class_names("font-semibold", SIZE_STYLES[size], TERM_GAP_STYLES[term_gap])
  end

  def detail_classes
    class_names("font-medium", SIZE_STYLES[size])
  end
end
