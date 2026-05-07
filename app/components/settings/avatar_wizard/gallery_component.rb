class Settings::AvatarWizard::GalleryComponent < ApplicationViewComponent
  option :avatars
  option :active_avatar_id, default: -> {}
end
