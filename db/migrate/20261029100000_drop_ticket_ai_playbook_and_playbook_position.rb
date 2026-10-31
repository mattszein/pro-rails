class DropTicketAiPlaybookAndPlaybookPosition < ActiveRecord::Migration[8.1]
  def change
    remove_reference :tickets, :ai_playbook, foreign_key: {to_table: :support_ai_playbooks, on_delete: :nullify}, index: true
    remove_column :support_ai_playbooks, :position, :integer, default: 0, null: false
  end
end
