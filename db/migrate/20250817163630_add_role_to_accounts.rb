class AddRoleToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_reference :accounts, :role, null: true, foreign_key: true
  end
end
