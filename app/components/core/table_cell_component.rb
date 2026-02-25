class Core::TableCellComponent < ApplicationViewComponent
  option :classes, default: -> { "" }

  def call
    content_tag :td, content, class: cell_classes
  end

  private

  def cell_classes
    class_names("px-4 py-2", classes)
  end
end
