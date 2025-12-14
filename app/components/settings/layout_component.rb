class Settings::LayoutComponent < ViewComponent::Base
  attr_reader :active_section

  def sections
    [
      Core::SubmenuComponent::Section.new(key: :profile, name: "Profile", path: "#"),
      Core::SubmenuComponent::Section.new(key: :appearance, name: "Appearance", path: helpers.settings_appearance_index_path),
      Core::SubmenuComponent::Section.new(key: :password, name: "Password", path: helpers.rodauth.change_password_path),
      Core::SubmenuComponent::Section.new(key: :remember, name: "Remember", path: helpers.rodauth.remember_path)
    ].freeze
  end

  def initialize(active_section:)
    @active_section = active_section
  end
end
