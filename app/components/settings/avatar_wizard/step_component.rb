# frozen_string_literal: true

class Settings::AvatarWizard::StepComponent < ApplicationViewComponent
  option :step
  option :total
  option :title
  option :subtitle, default: -> {}

  def progress_percent
    (step.to_f / total * 100).round
  end
end
