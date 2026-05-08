class Settings::AvatarWizard::StepComponent < ApplicationViewComponent
  option :step
  option :total
  option :title
  option :subtitle, default: -> {}
end
