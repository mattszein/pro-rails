class Core::Table::HeaderCellComponent < ApplicationViewComponent
  option :column
  option :current_sort, default: -> {}
  option :current_direction, default: -> { "desc" }

  def sortable?
    column[:sort_key].present?
  end

  def active?
    current_sort.to_s == column[:sort_key].to_s
  end

  def sort_indicator
    return unless active?
    (current_direction == "asc") ? "↑" : "↓"
  end

  def sort_url
    new_direction = (active? && current_direction == "asc") ? "desc" : "asc"
    query = helpers.request.query_parameters
      .merge("sort" => column[:sort_key].to_s, "direction" => new_direction)
      .except("page")
    helpers.request.path + (query.any? ? "?#{query.to_query}" : "")
  end
end
