class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :ticket, null: false, foreign_key: true

      t.timestamps
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :messages, [:conversation_id, :created_at]
  end
end
