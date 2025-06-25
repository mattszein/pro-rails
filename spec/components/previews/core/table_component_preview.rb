class Core::TableComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Core::TableComponent.new(rows: collection)) do |table|
      table.column("Name") { |coll| coll[:name] }
      table.column("Email") { |coll| coll[:email] }
    end
  end

  private

  def collection
    [{name: "John Doe", email: "john.doe@gmail.comn"}, {name: "Jane Doe", email: "jane.doe@gmail.com"}]
  end
end
