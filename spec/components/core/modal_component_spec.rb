require "rails_helper"

RSpec.describe Core::ModalComponent, type: :component do
  it "renders the title and content at the default width" do
    render_inline(described_class.new(title: "Hello")) { "Body" }

    expect(page).to have_css("turbo-frame#modal h3", text: "Hello")
    expect(page).to have_text("Body")
    expect(page).to have_css(".max-w-2xl")
    expect(page).not_to have_css(".max-w-5xl")
  end

  it "renders a wider dialog with size: :xl" do
    render_inline(described_class.new(title: "Wide", size: :xl)) { "Body" }

    expect(page).to have_css(".max-w-5xl")
    expect(page).not_to have_css(".max-w-2xl")
  end

  it "rejects an unknown size" do
    expect { render_inline(described_class.new(size: :huge)) }.to raise_error(KeyError)
  end
end
