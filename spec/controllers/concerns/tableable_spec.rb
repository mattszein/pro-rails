require "rails_helper"

RSpec.describe Tableable do
  let(:includer) { Class.new { include Tableable }.new }

  describe "#column_filters" do
    it "builds a scope-backed filter for a column whose filter declares scope:" do
      column = Core::Table::Column.new(
        label: "Title",
        filter: Core::Table::Filter.new(type: :text, param: :search, scope: :search_title)
      )

      filters = includer.send(:column_filters, Support::Ticket, [column])

      expect(filters[:search]).to eq(:search_title)
    end

    it "builds a generic equality filter when the column's filter has no scope: and the param is a real column" do
      column = Core::Table::Column.new(
        label: "Status",
        filter: Core::Table::Filter.new(type: :select, param: :status, options: -> { [] })
      )

      filters = includer.send(:column_filters, Support::Ticket, [column])
      relation = Support::Ticket.all

      expect(filters[:status]).to respond_to(:call)
      expect(filters[:status].call(relation, "open").to_sql).to include(%(WHERE "tickets"."status" = 0))
    end

    it "raises ArgumentError when the filter has no scope: and no matching column on the model" do
      column = Core::Table::Column.new(
        label: "Bogus",
        filter: Core::Table::Filter.new(type: :text, param: :not_a_real_column)
      )

      expect {
        includer.send(:column_filters, Support::Ticket, [column])
      }.to raise_error(ArgumentError, /needs a scope/)
    end

    it "ignores columns without a filter" do
      column = Core::Table::Column.new(label: "Title", sort_key: :title)

      expect(includer.send(:column_filters, Support::Ticket, [column])).to eq({})
    end
  end
end
