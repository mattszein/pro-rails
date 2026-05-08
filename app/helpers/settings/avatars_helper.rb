
module Settings::AvatarsHelper
  def avatar_status_badge(avatar)
    if avatar.generating?
      content_tag(:span, class: "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300") do
        content_tag(:span, "", class: "w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse") +
          t("avatars.in_progress.status.generating")
      end
    elsif avatar.failed?
      content_tag(:span, t("avatars.in_progress.status.failed"),
        class: "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300")
    else
      content_tag(:span, t("avatars.in_progress.status.draft"),
        class: "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300")
    end
  end

  def avatar_state_component(avatar, wizard_step: nil)
    case avatar.state_for_view
    when :wizard
      render Settings::AvatarWizard::WizardContainerComponent.new(avatar: avatar, wizard_step: wizard_step)
    when :generating
      render Settings::AvatarWizard::GeneratingComponent.new(avatar: avatar)
    when :completed
      render partial: "settings/avatars/result", locals: {avatar: avatar}
    when :failed
      render Settings::AvatarWizard::GenerationErrorComponent.new(
        avatar: avatar, error: t("avatars.generation.failed")
      )
    end
  end
end
