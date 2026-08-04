require "rails_helper"

RSpec.describe Core::SubmenuComponent, type: :component do
  it "renders links for each section" do
    sections = [
      Core::SubmenuComponent::Section.new(key: :profile, name: "Profile", path: "/settings/profile"),
      Core::SubmenuComponent::Section.new(key: :appearance, name: "Appearance", path: "/settings/appearance")
    ]

    render_inline(described_class.new(sections: sections, current_section: :profile))

    expect(page).to have_link("Profile", href: "/settings/profile")
    expect(page).to have_link("Appearance", href: "/settings/appearance")
  end

  it "only renders the underline span on the active section" do
    sections = [
      Core::SubmenuComponent::Section.new(key: :profile, name: "Profile", path: "/settings/profile"),
      Core::SubmenuComponent::Section.new(key: :appearance, name: "Appearance", path: "/settings/appearance")
    ]

    render_inline(described_class.new(sections: sections, current_section: :profile))

    active_link = page.find("a[aria-current='page']")
    inactive_link = page.find("a:not([aria-current='page'])")

    expect(active_link).to have_css("span")
    expect(inactive_link).to have_no_css("span")
  end

  it "raises when a section is missing the required path" do
    sections = [{key: :profile, name: "Profile"}]

    expect {
      render_inline(described_class.new(sections: sections, current_section: :profile))
    }.to raise_error(ArgumentError)
  end

  it "renders nothing when sections are empty" do
    render_inline(described_class.new(current_section: :profile))

    expect(page).to have_no_link
  end
end
