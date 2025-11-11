class Core::TableCellComponent < ViewComponent::Base
  def initialize(options: {})
    @options = options
    @custom_classes = options.fetch(:classes, "")
  end

  def call
    content_tag :td, content, class: cell_classes
  end

  private

  def cell_classes
    base_classes = "px-4 py-2"
    [base_classes, @custom_classes].compact.join(" ")
  end
end
