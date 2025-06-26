class Core::DrawerComponent < ViewComponent::Base
  attr_reader :title

  def initialize(title: nil, options: {})
    @title = title
  end
end
