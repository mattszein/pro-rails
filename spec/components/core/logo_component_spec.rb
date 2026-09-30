require "rails_helper"

RSpec.describe Core::LogoComponent, type: :component do
  it "renders both mark and lockup by default, swapped by breakpoint" do
    render_inline(described_class.new)

    expect(page).to have_css("svg.sm\\:hidden", count: 1)
    expect(page).to have_css("svg.hidden.sm\\:block", count: 1)
  end

  it "renders only the mark for the :mark variant" do
    render_inline(described_class.new(variant: :mark))

    expect(page).to have_css("svg", count: 1)
    expect(page).not_to have_css("svg path[style*='--pr-accent']")
  end

  it "renders only the lockup for the :lockup variant" do
    render_inline(described_class.new(variant: :lockup))

    expect(page).to have_css("svg", count: 1)
    expect(page).to have_css("svg path[style*='--pr-accent']")
  end

  it "binds the accent to the theme's primary color" do
    render_inline(described_class.new)

    expect(page).to have_css("span[class*='--pr-accent:var(--color-primary-500)']")
  end
end
