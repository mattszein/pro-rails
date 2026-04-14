# frozen_string_literal: true

class Settings::AvatarWizard::StepReviewComponent < ApplicationViewComponent
  option :avatar

  def last_step
    (avatar.read_attribute(:method) == 0) ? "6" : "5"
  end
end
