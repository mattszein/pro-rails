class Core::RowRendererComponent < ApplicationViewComponent
  option :row
  option :index
  option :block

  def call
    block.call(row, index)
  end
end
