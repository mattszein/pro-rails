class AddAiStateToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :ai_state, :integer, null: false, default: 0
    add_column :tickets, :ai_state_changed_at, :datetime
    add_column :tickets, :ai_reminded_at, :datetime
    add_reference :tickets, :ai_playbook, foreign_key: {to_table: :support_ai_playbooks, on_delete: :nullify}
    add_index :tickets, :ai_state
  end
end
