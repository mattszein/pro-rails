require "rails_helper"

RSpec.describe Adminit::BreadcrumbComponent, type: :component do
  def crumb(...) = Adminit::BreadcrumbComponent::Crumb.new(...)

  it "renders nothing when the trail has a single crumb" do
    render_inline(described_class.new(trail: [crumb(label: "Dash", path: "/adminit", icon: "home")]))

    expect(page).not_to have_css("nav")
  end

  it "renders non-final crumbs as links and the final crumb as an unlinked current span" do
    render_inline(described_class.new(trail: [
      crumb(label: "Dash", path: "/adminit", icon: "home"),
      crumb(label: "Tickets", path: "/adminit/tickets"),
      crumb(label: "#42 Foo", path: nil)
    ]))

    expect(page).to have_link("Dash", href: "/adminit")
    expect(page).to have_link("Tickets", href: "/adminit/tickets")

    current = page.find("span[aria-current='page']")
    expect(current).to have_text("#42 Foo")
    expect(page).not_to have_link("#42 Foo")
  end

  it "renders a crumb with a nil path unlinked even when it is not last" do
    render_inline(described_class.new(trail: [
      crumb(label: "Dash", path: "/adminit", icon: "home"),
      crumb(label: "Middle", path: nil),
      crumb(label: "Leaf", path: nil)
    ]))

    expect(page).not_to have_link("Middle")
    expect(page).to have_css("span", text: "Middle")
  end

  it "renders a separator between crumbs but not before the first" do
    render_inline(described_class.new(trail: [
      crumb(label: "Dash", path: "/adminit", icon: "home"),
      crumb(label: "Tickets", path: "/adminit/tickets")
    ]))

    expect(page.all("span[aria-hidden='true']", text: "/").size).to eq(1)
  end

  it "renders the home icon on the first crumb" do
    render_inline(described_class.new(trail: [
      crumb(label: "Dash", path: "/adminit", icon: "home"),
      crumb(label: "Tickets", path: "/adminit/tickets")
    ]))

    expect(page).to have_css("svg")
  end
end
