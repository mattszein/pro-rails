class Core::TableComponent < ApplicationViewComponent
  option :rows
  option :columns
  option :options, default: -> { {} }

  def tbody_id
    options.dig(:ids, :tbody)
  end

  def broadcast_id
    options.dig(:ids, :col_prefix)
  end

  def custom_row_renderer?
    content.present?
  end

  def frame_id
    options[:frame_id]
  end

  def pagy
    options[:pagy]
  end

  def sortable?
    options[:sortable]
  end

  def filterable?
    options[:filterable]
  end

  def current_sort
    helpers.params[:sort]
  end

  def current_direction
    helpers.params[:direction] || "desc"
  end

  def current_filters
    helpers.params[:filter]&.to_unsafe_h || {}
  end
end
