# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::Table::PaginationComponent, type: :component do
  def build_pagy(pages:, page: 1)
    instance_double(Pagy::Offset, pages: pages, page: page)
  end

  def real_pagy(count:, page: 1, limit: 20)
    Pagy::Offset.new(count: count, page: page, limit: limit)
  end

  describe "#render?" do
    it "returns false when pages <= 1" do
      component = described_class.new(pagy: build_pagy(pages: 1))
      expect(component.render?).to be false
    end

    it "returns true when pages > 1" do
      component = described_class.new(pagy: build_pagy(pages: 3))
      expect(component.render?).to be true
    end
  end

  describe "rendering" do
    it "produces pagination markup when multiple pages exist" do
      pagy = real_pagy(count: 100)
      # series_nav needs a live request context not available in unit tests;
      # stub the return value but verify the method contract still exists on Pagy.
      expect(pagy).to respond_to(:series_nav)
      allow(pagy).to receive(:series_nav).and_return("<nav>1 2 3</nav>".html_safe)
      render_inline(described_class.new(pagy: pagy))
      expect(rendered_content).to include("<nav>")
    end

    it "renders nothing when only one page" do
      pagy = real_pagy(count: 5)
      render_inline(described_class.new(pagy: pagy))
      expect(rendered_content).to be_empty
    end
  end
end
