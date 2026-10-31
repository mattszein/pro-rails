class AddSenderToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :sender, :integer, null: false, default: 0
    add_column :messages, :metadata, :jsonb, null: false, default: {}
    change_column_null :messages, :account_id, true
    add_check_constraint :messages,
      "(sender = 0 AND account_id IS NOT NULL) OR (sender = 1 AND account_id IS NULL)",
      name: "messages_sender_account_check"

    # Rolling back restores account_id NOT NULL, which AI messages (no author) cannot satisfy.
    reversible do |dir|
      dir.down { execute "DELETE FROM messages WHERE account_id IS NULL" }
    end
  end
end
