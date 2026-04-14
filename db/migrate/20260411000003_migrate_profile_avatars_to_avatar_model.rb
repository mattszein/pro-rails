# frozen_string_literal: true

class MigrateProfileAvatarsToAvatarModel < ActiveRecord::Migration[8.1]
  def up
    Profile.find_each do |profile|
      attachment = ActiveStorage::Attachment.find_by(
        record_type: "Profile",
        record_id: profile.id,
        name: "avatar"
      )
      next unless attachment

      avatar = Avatar.create!(
        profile_id: profile.id,
        kind: 0, # manual
        status: 2, # completed
        dna: {}
      )

      ActiveStorage::Attachment.create!(
        name: "image",
        record_type: "Avatar",
        record_id: avatar.id,
        blob_id: attachment.blob_id
      )

      profile.update_column(:avatar_id, avatar.id)
    end
  end

  def down
    Avatar.where(kind: 0).find_each do |avatar|
      attachment = ActiveStorage::Attachment.find_by(
        record_type: "Avatar",
        record_id: avatar.id,
        name: "image"
      )
      next unless attachment

      profile = Profile.find_by(id: avatar.profile_id)
      next unless profile

      # Restore the profile's direct avatar attachment
      existing = ActiveStorage::Attachment.find_by(
        record_type: "Profile",
        record_id: profile.id,
        name: "avatar"
      )
      unless existing
        ActiveStorage::Attachment.create!(
          name: "avatar",
          record_type: "Profile",
          record_id: profile.id,
          blob_id: attachment.blob_id
        )
      end

      profile.update_column(:avatar_id, nil)
      avatar.destroy
    end
  end
end
