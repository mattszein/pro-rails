require "rails_helper"

RSpec.describe Core::CodeBlockComponent, type: :component do
  it "renders the text inside a pre" do
    render_inline(described_class.new(text: "line one\nline two"))

    expect(page).to have_css("pre", text: "line one")
    expect(page).to have_css("pre.whitespace-pre-wrap.overflow-auto")
  end

  it "escapes the text" do
    render_inline(described_class.new(text: "<script>alert(1)</script>"))

    expect(page).not_to have_css("script", visible: :all)
    expect(page.native.to_html).to include("&lt;script&gt;")
  end

  it "defaults to the medium max height and supports sm and lg" do
    render_inline(described_class.new(text: "x"))
    expect(page).to have_css("pre.max-h-72")

    render_inline(described_class.new(text: "x", max_height: :sm))
    expect(page).to have_css("pre.max-h-40")

    render_inline(described_class.new(text: "x", max_height: :lg))
    expect(page).to have_css("pre[class*='max-h-[32rem]']")
  end

  it "passes extra classes and html options such as data-role" do
    render_inline(described_class.new(text: "x", classes: "mt-2", html_options: {data: {role: "ai-run-output"}}))

    expect(page).to have_css("pre.mt-2[data-role='ai-run-output']")
  end

  it "renders nil text as an empty block" do
    render_inline(described_class.new(text: nil))

    expect(page).to have_css("pre", text: "")
  end
end
