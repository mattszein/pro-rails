class Core::TableComponent < ViewComponent::Base
  def initialize(rows:)
    @rows = rows
    @columns = []
  end

  def column(label, &block)
    @columns << Column.new(label, &block)
  end

  def before_render
    content
  end

  class Column
    attr_reader :label, :td_block
    def initialize(label, &td_block)
      @label = label
      @td_block = td_block
    end
  end
end
