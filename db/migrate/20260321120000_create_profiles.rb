class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :account, null: false, foreign_key: true, index: {unique: true}
      t.string :username
      t.text :bio

      t.timestamps
    end

    add_index :profiles, :username, unique: true, where: "username IS NOT NULL AND username != ''"
  end
end
