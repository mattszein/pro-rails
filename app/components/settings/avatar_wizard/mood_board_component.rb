class Settings::AvatarWizard::MoodBoardComponent < ApplicationViewComponent
  option :prompts
  option :selected_indices, default: -> { [] }
end
