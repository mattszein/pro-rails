class AddAvatarIdToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :profiles, :avatar, null: true, foreign_key: true
  end
end
