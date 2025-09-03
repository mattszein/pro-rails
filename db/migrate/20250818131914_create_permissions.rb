class CreatePermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :permissions do |t|
      t.string :resource
      t.index :resource, unique: true

      t.timestamps
    end
  end
end
