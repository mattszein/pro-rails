# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::Table::HeaderCellComponent, type: :component do
  let(:plain_column) { {label: "Name"} }
  let(:sortable_column) { {label: "Status", sort_key: :status} }

  before do
    allow_any_instance_of(described_class).to receive_message_chain(:helpers, :request, :query_parameters).and_return({})
    allow_any_instance_of(described_class).to receive_message_chain(:helpers, :request, :path).and_return("/test")
  end

  describe "without sort_key" do
    it "renders plain th without a link" do
      render_inline described_class.new(column: plain_column)
      expect(page).to have_selector("th")
      expect(page).not_to have_selector("a")
      expect(page).to have_text("Name")
    end
  end

  describe "with sort_key" do
    it "renders th with a sort link" do
      render_inline described_class.new(column: sortable_column)
      expect(page).to have_selector("th a")
      expect(page).to have_text("Status")
    end

    context "when active with asc direction" do
      it "shows ascending indicator" do
        render_inline described_class.new(column: sortable_column, current_sort: "status", current_direction: "asc")
        expect(rendered_content).to include("↑")
      end
    end

    context "when active with desc direction" do
      it "shows descending indicator" do
        render_inline described_class.new(column: sortable_column, current_sort: "status", current_direction: "desc")
        expect(rendered_content).to include("↓")
      end
    end

    context "when not active" do
      it "shows neutral indicator" do
        render_inline described_class.new(column: sortable_column, current_sort: "title", current_direction: "asc")
        expect(rendered_content).to include("↕")
      end
    end
  end
end
