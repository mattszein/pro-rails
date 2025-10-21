class Core::TableRowComponent < ViewComponent::Base
  attr_reader :row, :columns, :broadcast_id, :index

  def initialize(table_row:, columns:, broadcast_id: nil, index: 0)
    @row = table_row
    @columns = columns
    @broadcast_id = broadcast_id
    @index = index
  end
end
