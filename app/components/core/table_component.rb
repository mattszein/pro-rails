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
end
