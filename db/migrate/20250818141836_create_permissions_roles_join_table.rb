class CreatePermissionsRolesJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :permissions, :roles do |t|
      t.index [:permission_id, :role_id], unique: true
      t.index :role_id
      t.index :permission_id
    end
  end
end
