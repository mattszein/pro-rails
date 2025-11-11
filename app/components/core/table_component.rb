class Core::TableComponent < ViewComponent::Base
  attr_reader :rows, :columns, :options

  def initialize(rows:, columns:, options: {})
    @rows = rows
    @columns = columns
    @options = options
  end

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
