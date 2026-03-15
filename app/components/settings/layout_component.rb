class Settings::LayoutComponent < ApplicationViewComponent
  option :active_section

  def sections
    [
      Core::SubmenuComponent::Section.new(key: :profile, name: I18n.t("views.settings.profile"), path: "#"),
      Core::SubmenuComponent::Section.new(key: :appearance, name: I18n.t("views.settings.appearance"), path: helpers.settings_appearance_index_path),
      Core::SubmenuComponent::Section.new(key: :password, name: I18n.t("views.settings.password"), path: helpers.rodauth.change_password_path),
      Core::SubmenuComponent::Section.new(key: :remember, name: I18n.t("views.settings.remember"), path: helpers.rodauth.remember_path)
    ]
  end
end
