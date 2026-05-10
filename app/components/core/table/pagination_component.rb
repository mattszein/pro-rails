class Core::Table::PaginationComponent < ApplicationViewComponent
  option :pagy

  def render?
    pagy.pages > 1
  end
end
