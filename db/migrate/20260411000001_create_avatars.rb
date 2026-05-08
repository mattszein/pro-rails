
class CreateAvatars < ActiveRecord::Migration[8.1]
  def change
    create_table :avatars do |t|
      t.references :profile, null: false, foreign_key: true
      t.integer :kind, null: false
      t.integer :method
      t.integer :dna_version
      t.jsonb :dna, null: false, default: {}
      t.text :assembled_prompt
      t.integer :status, null: false, default: 0
      t.string :image_model
      t.boolean :visible, null: false, default: true

      t.timestamps
    end

    add_index :avatars, [:profile_id, :status]
    add_index :avatars, [:profile_id, :visible]
    add_index :avatars, [:profile_id, :kind]
  end
end
