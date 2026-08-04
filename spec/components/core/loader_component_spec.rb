require "rails_helper"

RSpec.describe Core::LoaderComponent, type: :component do
  it "renders without an id or data-turbo-permanent by default" do
    render_inline(described_class.new) { "content" }

    expect(page).to have_css("div.is-loading[data-controller='core--loader-component']")
    expect(page).not_to have_css("[data-turbo-permanent]")
    expect(page).to have_text("content")
  end

  it "marks the wrapper data-turbo-permanent when given an id" do
    render_inline(described_class.new(id: "widget_loader")) { "content" }

    expect(page).to have_css("div#widget_loader[data-turbo-permanent]")
  end
end
