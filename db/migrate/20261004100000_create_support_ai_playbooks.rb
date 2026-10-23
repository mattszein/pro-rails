class CreateSupportAiPlaybooks < ActiveRecord::Migration[8.1]
  def change
    create_table :support_ai_playbooks do |t|
      t.string :name, null: false
      t.boolean :enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.boolean :is_default, null: false, default: false
      t.integer :categories, array: true, null: false, default: []
      t.integer :min_priority
      t.integer :max_priority
      t.references :audience, foreign_key: {on_delete: :nullify}
      t.integer :mode, null: false, default: 1
      t.text :instructions
      t.string :capabilities, array: true, null: false, default: []
      t.integer :max_ai_turns, null: false, default: 4
      t.integer :idle_reminder_after_hours, null: false, default: 24
      t.integer :idle_handoff_after_hours, null: false, default: 48

      t.timestamps
    end

    add_index :support_ai_playbooks, :name, unique: true
    add_index :support_ai_playbooks, :is_default, unique: true, where: "is_default", name: "index_support_ai_playbooks_single_default"
  end
end
