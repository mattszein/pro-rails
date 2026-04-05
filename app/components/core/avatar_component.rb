class Core::AvatarComponent < ApplicationViewComponent
  option :profile
  option :size, default: -> { :md }

  SIZE_CLASSES = {
    sm: "h-8 w-8 text-xs",
    md: "h-12 w-12 text-sm",
    lg: "h-16 w-16 text-base",
    xl: "h-24 w-24 text-xl"
  }.freeze

  def avatar_variant
    (size == :sm) ? :thumb : :medium
  end

  def size_class
    SIZE_CLASSES.fetch(size, SIZE_CLASSES[:md])
  end

  def fallback_initial
    profile.username&.first&.upcase || "?"
  end
end
