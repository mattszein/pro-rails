# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::Table::PaginationComponent, type: :component do
  def build_pagy(pages:, page: 1)
    instance_double(Pagy, pages: pages, page: page)
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
end
