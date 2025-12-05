class Settings::LayoutComponent < ViewComponent::Base
  attr_reader :active_section

  MENU_ITEMS = [
    Core::SubmenuComponent::Section.new(key: :profile, name: "Profile", path: "#"),
    Core::SubmenuComponent::Section.new(key: :appearance, name: "Appearance", path: Rails.application.routes.url_helpers.settings_appearance_index_path),
    Core::SubmenuComponent::Section.new(key: :security, name: "Security", path: "#")
  ].freeze

  def initialize(active_section:)
    @active_section = active_section
  end
end
