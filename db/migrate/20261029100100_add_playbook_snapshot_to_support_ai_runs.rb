class AddPlaybookSnapshotToSupportAiRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :support_ai_runs, :playbook_snapshot, :jsonb, default: {}, null: false
  end
end
