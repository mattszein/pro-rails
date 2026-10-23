class CreateSupportAiRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :support_ai_runs do |t|
      t.references :ticket, null: false, foreign_key: {on_delete: :cascade}
      t.references :playbook, foreign_key: {to_table: :support_ai_playbooks, on_delete: :nullify}
      t.integer :run_trigger, null: false
      t.integer :step, null: false
      t.string :model
      t.integer :status, null: false
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :latency_ms
      t.jsonb :tool_calls, null: false, default: []
      t.jsonb :output, null: false, default: {}
      t.text :error

      t.timestamps
    end

    add_index :support_ai_runs, [:ticket_id, :created_at]
  end
end
