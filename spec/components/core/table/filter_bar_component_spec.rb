# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::Table::FilterBarComponent, type: :component do
  let(:columns) do
    [
      Core::Table::Column.new(label: "Title", renderer: ->(r) { r }, filter: Core::Table::Filter.new(type: :text, param: :search)),
      Core::Table::Column.new(label: "Status", renderer: ->(r) { r }, filter: Core::Table::Filter.new(type: :select, param: :status, options: -> { [["Open", "open"], ["Closed", "closed"]] })),
      Core::Table::Column.new(label: "Actions", renderer: ->(r) { r })
    ]
  end

  before do
    allow_any_instance_of(described_class).to receive_message_chain(:helpers, :request, :path).and_return("/test")
  end

  it "renders inputs only for filterable columns" do
    render_inline described_class.new(columns: columns)
    expect(page).to have_selector("input[name='filter[search]']")
    expect(page).to have_selector("select[name='filter[status]']")
  end

  it "does not render an input for non-filterable columns" do
    render_inline described_class.new(columns: columns)
    expect(page).not_to have_selector("input[name='filter[actions]']")
  end

  it "preserves current filter values" do
    render_inline described_class.new(columns: columns, current_filters: {"search" => "foo"})
    expect(page).to have_selector("input[name='filter[search]'][value='foo']")
  end

  it "includes a clear filters link" do
    render_inline described_class.new(columns: columns)
    expect(page).to have_selector("a[href='/test']")
  end

  it "renders hidden field for current sort when present" do
    render_inline described_class.new(columns: columns, current_sort: "status", current_direction: "desc")
    expect(rendered_content).to include("name=\"sort\"")
    expect(rendered_content).to include("name=\"direction\"")
  end
end
