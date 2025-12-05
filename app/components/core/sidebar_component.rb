class Core::SidebarComponent < ViewComponent::Base
  attr_reader :open, :title, :navigation_items

  def initialize(open: false, title: "", navigation_items: nil)
    @title = title
    @open = open
    @navigation_items = navigation_items || []
  end

  private
end
