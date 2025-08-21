class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string :title
      t.text :description
      t.integer :priority, default: 4
      t.integer :status, default: 0
      t.references :created, null: true, foreign_key: {to_table: :accounts}
      t.references :assigned, null: true, foreign_key: {to_table: :accounts}

      t.timestamps
    end
  end
end
