require "rails_helper"

RSpec.describe Core::TabsComponent, type: :component do
  def render_tabs(names)
    render_inline(described_class.new) do |tabs|
      names.each_with_index do |name, i|
        tabs.with_tab(name: name) { "Panel #{i}" }
      end
    end
  end

  it "renders a button and a panel for every tab" do
    render_tabs(%w[Personal General Analytics])

    expect(page.all("[role='tab']").size).to eq(3)
    expect(page.all("[role='tabpanel']").size).to eq(3)

    button = page.find("button[data-index='1']")
    expect(button).to have_text("General")
    expect(button["data-tabs-target"]).to eq("tab")
  end

  it "activates the first tab and panel, hiding the rest" do
    render_tabs(%w[Personal General])

    expect(page.find("button[data-index='0']")["aria-selected"]).to eq("true")
    expect(page.find("button[data-index='1']")["aria-selected"]).to eq("false")

    expect(page.find("[role='tabpanel'][data-index='0']")[:class]).not_to include("hidden")
    expect(page.find("[role='tabpanel'][data-index='1']")[:class]).to include("hidden")
  end

  it "renders each tab's panel body" do
    render_tabs(%w[Personal General])

    expect(page.find("[role='tabpanel'][data-index='1']")).to have_text("Panel 1")
  end

  it "renders the underline span on every tab" do
    render_tabs(%w[Personal General])

    expect(page).to have_css("button span", count: 2)
  end

  it "wires the tabs stimulus controller with the submenu class values" do
    render_tabs(%w[Personal])

    root = page.find("[data-controller='tabs']")
    expect(root["data-tabs-active-classes-value"]).to eq(Core::SubmenuStyles::ACTIVE_CLASSES)
    expect(root["data-tabs-inactive-classes-value"]).to eq(Core::SubmenuStyles::INACTIVE_CLASSES)
  end
end
