class Core::ModalComponent < ViewComponent::Base
  include Turbo::FramesHelper
  attr_reader :title

  def initialize(title: nil)
    @title = title
  end
end
