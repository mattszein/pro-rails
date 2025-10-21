class Core::TableComponent < ViewComponent::Base
  def initialize(rows:, columns: nil, options: {ids: {tbody: nil, col_prefix: nil}})
    @rows = rows
    @columns = columns || []       # use passed columns if any
    @tbody_id = options[:ids][:tbody]
    @broadcast_id = options[:ids][:col_prefix]
  end

  # old DSL method: allows incremental refactoring
  def column(label, &block)
    @columns << {label: label, renderer: block}
  end
end
