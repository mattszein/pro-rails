class CreateFeatureFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_flags do |t|
      t.string :key, null: false

      t.timestamps
    end
    add_index :feature_flags, :key, unique: true

    create_table :audiences do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :archived_at

      t.timestamps
    end
    add_index :audiences, :name, unique: true
    add_index :audiences, :archived_at

    create_table :audience_conditions do |t|
      t.references :audience, null: false, foreign_key: {on_delete: :cascade}
      t.string :condition_key, null: false
      t.jsonb :value, null: false

      t.timestamps
    end
    add_index :audience_conditions, [:audience_id, :condition_key], unique: true

    create_table :feature_flag_audiences do |t|
      t.references :feature_flag, null: false, foreign_key: {on_delete: :cascade}
      t.references :audience, null: false, foreign_key: {on_delete: :restrict}

      t.timestamps
    end
    add_index :feature_flag_audiences, [:feature_flag_id, :audience_id], unique: true,
      name: "index_feature_flag_audiences_on_flag_and_audience"

    create_table :feature_flag_accounts do |t|
      t.references :feature_flag, null: false, foreign_key: {on_delete: :cascade}
      t.references :account, null: false, foreign_key: {on_delete: :cascade}
      t.integer :access, null: false

      t.timestamps
    end
    add_index :feature_flag_accounts, [:feature_flag_id, :account_id], unique: true,
      name: "index_feature_flag_accounts_on_flag_and_account"
  end
end
