class Core::Table::FilterBarComponent < ApplicationViewComponent
  option :columns
  option :current_filters, default: -> { {} }
  option :current_sort, default: -> {}
  option :current_direction, default: -> {}

  def filterable_columns
    columns.select(&:filterable?)
  end
end
