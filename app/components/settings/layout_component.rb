class Settings::LayoutComponent < ViewComponent::Base
  attr_reader :active_section

  def sections
    [
      Core::SubmenuComponent::Section.new(key: :profile, name: "Profile", path: "#"),
      Core::SubmenuComponent::Section.new(key: :appearance, name: "Appearance", path: helpers.settings_appearance_index_path),
      Core::SubmenuComponent::Section.new(key: :security, name: "Security", path: "#")
    ].freeze
  end

  def initialize(active_section:)
    @active_section = active_section
  end
end
