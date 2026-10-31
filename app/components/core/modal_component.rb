class Core::ModalComponent < ApplicationViewComponent
  include Turbo::FramesHelper

  SIZE_STYLES = {
    md: "max-w-2xl",
    xl: "max-w-5xl"
  }.freeze

  option :title, default: -> {}
  option :size, default: -> { :md }

  def size_classes
    SIZE_STYLES.fetch(size)
  end
end
