class Core::TableRowComponent < ApplicationViewComponent
  option :table_row
  option :columns
  option :broadcast_id, default: -> {}
  option :index, default: -> { 0 }
end
