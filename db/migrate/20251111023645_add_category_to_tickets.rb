class AddCategoryToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :category, :integer, default: 0, null: false
  end
end
