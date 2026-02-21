class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.integer :status, default: 0, null: false
      t.datetime :scheduled_at
      t.datetime :published_at
      t.references :author, null: false, foreign_key: {to_table: :accounts}

      t.timestamps
    end

    add_index :announcements, :status
    add_index :announcements, [:status, :scheduled_at]
  end
end
