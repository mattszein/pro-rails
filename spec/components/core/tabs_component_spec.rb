require "rails_helper"

RSpec.describe Core::TabsComponent, type: :component do
  it "renders tab buttons with the expected data attributes" do
    sections = [
      Core::TabsComponent::Section.new(key: :personal, name: "Personal", panel_id: 0),
      Core::TabsComponent::Section.new(key: :general, name: "General", panel_id: 1),
      Core::TabsComponent::Section.new(key: :analytics, name: "Analytics", panel_id: 2)
    ]

    render_inline(described_class.new(sections: sections, current_section: :personal))

    buttons = page.all("[role='tab']")
    expect(buttons.size).to eq(3)

    sections.each do |section|
      button = page.find("button[data-index='#{section.panel_id}']")
      expect(button).to have_text(section.name)
      expect(button["data-tabs-target"]).to eq("tab")
    end
  end

  it "marks the current section as selected" do
    sections = [
      Core::TabsComponent::Section.new(key: :personal, name: "Personal", panel_id: 0),
      Core::TabsComponent::Section.new(key: :general, name: "General", panel_id: 1)
    ]

    render_inline(described_class.new(sections: sections, current_section: :general))

    expect(page.find("button[data-index='0']")["aria-selected"]).to eq("false")
    expect(page.find("button[data-index='1']")["aria-selected"]).to eq("true")
  end

  it "renders the underline span on every tab" do
    sections = [
      Core::TabsComponent::Section.new(key: :personal, name: "Personal", panel_id: 0),
      Core::TabsComponent::Section.new(key: :general, name: "General", panel_id: 1)
    ]

    render_inline(described_class.new(sections: sections, current_section: :personal))

    expect(page).to have_css("button span", count: 2)
  end

  it "raises when a section is missing the required panel_id" do
    sections = [{key: :personal, name: "Personal"}]

    expect {
      render_inline(described_class.new(sections: sections, current_section: :personal))
    }.to raise_error(ArgumentError)
  end
end
