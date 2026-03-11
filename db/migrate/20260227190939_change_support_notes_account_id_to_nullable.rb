class ChangeSupportNotesAccountIdToNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :support_notes, :account_id, true
  end
end
