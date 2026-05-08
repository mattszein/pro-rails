# frozen_string_literal: true

class Settings::AvatarWizard::WizardContainerComponent < ApplicationViewComponent
  option :avatar
  option :wizard_step, default: -> {}

  def current_step
    wizard_step || avatar.wizard_resume_step
  end

  def step_component
    return nil unless (step = current_step)
    config = Settings::AvatarWizard::StepConfig.for(avatar.generation_method, step)
    Settings::AvatarWizard::StepConfig.component_class(config).new(avatar: avatar, config: config)
  end
end
