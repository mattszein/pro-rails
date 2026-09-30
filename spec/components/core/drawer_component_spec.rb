require "rails_helper"

RSpec.describe Core::DrawerComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(title: "App menu")) { "links" } }

  it "wires the drawer controller with outside-click and Escape closing" do
    rendered

    aside = page.find("aside#drawer[data-controller='core--drawer-component']")
    expect(aside["data-action"]).to include("click@window->core--drawer-component#closeOnOutsideClick")
    expect(aside["data-action"]).to include("keydown.esc@window->core--drawer-component#close")
  end

  it "keeps hover opening and adds a data-open state for touch" do
    rendered

    expect(page).to have_css("aside.hover\\:w-80.data-open\\:w-80")
  end

  it "renders the label as a toggle button" do
    rendered

    button = page.find("button[data-action='core--drawer-component#toggle']")
    expect(button["aria-controls"]).to eq("drawer")
    expect(button["aria-expanded"]).to eq("false")
    expect(button).to have_css("svg[aria-label='pro-rails']")
    expect(page).to have_text("links")
  end
end
