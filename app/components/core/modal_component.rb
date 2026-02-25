class Core::ModalComponent < ApplicationViewComponent
  include Turbo::FramesHelper

  option :title, default: -> {}
end
