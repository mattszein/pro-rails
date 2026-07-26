class Settings::AvatarWizard::GalleryItemComponent < ApplicationViewComponent
  option :avatar
  option :active_avatar_id, default: -> {}

  def active?
    active_avatar_id == avatar.id
  end
end
