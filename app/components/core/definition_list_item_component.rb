# app/components/core/definition_list_item_component.rb
class Core::DefinitionListItemComponent < ViewComponent::Base
  attr_reader :term, :size, :term_gap

  SIZES = {
    xs: {term: "text-xs", detail: "text-xs"},
    sm: {term: "text-sm", detail: "text-sm"},
    base: {term: "text-base", detail: "text-base"},
    lg: {term: "text-lg", detail: "text-lg"}
  }.freeze

  TERM_GAP = {
    none: "pr-0",
    xs: "pr-2",
    sm: "pr-3",
    md: "pr-4",
    lg: "pr-6"
  }.freeze

  DEFAULT = {
    size: :sm,
    term_gap: :sm
  }.freeze

  def initialize(term:, **options)
    @term = term
    @size = options.fetch(:size, DEFAULT[:size])
    @term_gap = options.fetch(:term_gap, DEFAULT[:term_gap])
  end

  def term_classes
    [
      SIZES[@size][:term],
      TERM_GAP[@term_gap],
      "font-semibold"
    ].join(" ")
  end

  def detail_classes
    [
      SIZES[@size][:detail],
      "font-medium"
    ].join(" ")
  end
end
