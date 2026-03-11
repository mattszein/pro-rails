class CreateSupportNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :support_notes do |t|
      t.text :body
      t.integer :kind
      t.references :ticket, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
