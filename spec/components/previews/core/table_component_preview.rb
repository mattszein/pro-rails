class Core::TableComponentPreview < ViewComponent::Preview
  # @label Plain table (no features)
  def default
    render(Core::TableComponent.new(rows: collection, columns: plain_columns))
  end

  # @label Sortable headers
  def sortable
    render(Core::TableComponent.new(
      rows: collection,
      columns: sortable_columns,
      options: {sortable: true}
    ))
  end

  # @label With pagination
  def with_pagination
    pagy = build_preview_pagy(count: 100)
    render(Core::TableComponent.new(
      rows: collection,
      columns: plain_columns,
      options: {
        frame_id: "preview_table",
        pagy: pagy
      }
    ))
  end

  # @label Full featured (sort + filter + pagination + frame)
  def full_featured
    pagy = build_preview_pagy(count: 100)
    render(Core::TableComponent.new(
      rows: collection,
      columns: sortable_columns,
      options: {
        frame_id: "preview_full_table",
        pagy: pagy,
        sortable: true,
        filterable: true
      }
    ))
  end

  # @label Empty state
  def empty
    render(Core::TableComponent.new(rows: [], columns: plain_columns))
  end

  private

  # Pagy::Offset requires a request object to compose page URLs.
  # We supply a minimal struct that satisfies compose_page_url's interface.
  def build_preview_pagy(count: 100, page: 1)
    request_stub = Struct.new(:base_url, :path, :params, :cookie)
      .new("http://localhost:3000", "/", {}, nil)
    Pagy::Offset.new(count: count, page: page, limit: 20, request: request_stub)
  end

  def plain_columns
    [
      {label: "Name", renderer: ->(row) { row[:name] }},
      {label: "Email", renderer: ->(row) { row[:email] }}
    ]
  end

  def sortable_columns
    [
      {label: "Name", renderer: ->(row) { row[:name] }, sort_key: :name},
      {
        label: "Status",
        renderer: ->(row) { row[:status] },
        sort_key: :status,
        filter: {type: :select, param: :status, options: -> { [["Active", "active"], ["Inactive", "inactive"]] }}
      }
    ]
  end

  def collection
    [
      {name: "Alice Smith", email: "alice@example.com", status: "active"},
      {name: "Bob Jones", email: "bob@example.com", status: "inactive"}
    ]
  end
end
