# frozen_string_literal: true

class Settings::AvatarWizard::OptionCardComponent < ApplicationViewComponent
  option :name
  option :value
  option :label
  option :description, default: -> {}
  option :colors, default: -> { [] }
  option :selected, default: -> { false }

  def input_id
    "#{name.gsub(/[^\w]/, "_")}_#{value}"
  end
end
