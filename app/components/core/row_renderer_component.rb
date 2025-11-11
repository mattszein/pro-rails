class Core::RowRendererComponent < ViewComponent::Base
  def initialize(row:, index:, block:)
    @row = row
    @index = index
    @block = block
  end

  def call
    @block.call(@row, @index)
  end
end
