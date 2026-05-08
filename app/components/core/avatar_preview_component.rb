
# Renders any Avatar's image (draft, in-progress, completed, or manual).
# Used by gallery items and the profile display (replacing Core::AvatarComponent
# when a full Avatar record is available).
class Core::AvatarPreviewComponent < ApplicationViewComponent
  option :avatar
  option :size, default: -> { :md }
  option :ring_class, default: -> { "ring-transparent transition-all duration-200 group-hover:ring-secondary-500 group-[.selected]:ring-secondary-500" }

  SIZE_CLASSES = {
    sm: "w-10 h-10",
    md: "w-16 h-16",
    lg: "w-24 h-24",
    xl: "w-32 h-32",
    full: "w-full h-full"
  }.freeze

  VARIANT_MAP = {
    sm: :thumb,
    md: :thumb,
    lg: :medium,
    xl: :medium,
    full: :medium
  }.freeze

  def image_variant
    VARIANT_MAP[size] || :thumb
  end

  def size_class
    SIZE_CLASSES[size] || SIZE_CLASSES[:md]
  end
end
