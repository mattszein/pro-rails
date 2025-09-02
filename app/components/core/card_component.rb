class Core::CardComponent < ViewComponent::Base
  attr_accessor :padding, :classes, :variant, :glow

  PADDING = {
    none: "p-0",
    xs: "p-2",
    sm: "p-4",
    md: "p-8",
    lg: "p-12",
    xl: "p-16"
  }

  VARIANT_STYLES = {
    default: {
      base: "bg-highlight",
      border: "border border-violet-500/10 dark:border-violet-500/20",
      shadow: "shadow-lg shadow-violet-500/5 dark:shadow-violet-500/10",
      hover_shadow: "hover:shadow-xl hover:shadow-violet-500/10 dark:hover:shadow-violet-500/20 focus-within:shadow-xl focus-within:shadow-violet-500/10 dark:focus-within:shadow-violet-500/20"
    },
    primary: {
      base: "bg-highlight",
      border: "border border-violet-500/15 dark:border-violet-400/25",
      shadow: "shadow-lg shadow-violet-500/8 dark:shadow-violet-400/15",
      hover_shadow: "hover:shadow-xl hover:shadow-violet-500/15 dark:hover:shadow-violet-400/25"
    },
    secondary: {
      base: "bg-highlight",
      border: "border border-pink-500/15 dark:border-pink-400/25",
      shadow: "shadow-lg shadow-pink-500/8 dark:shadow-pink-400/15",
      hover_shadow: "hover:shadow-xl hover:shadow-pink-500/15 dark:hover:shadow-pink-400/25"
    },
    minimal: {
      base: "bg-highlight",
      border: "border border-gray-200/50 dark:border-gray-700/50",
      shadow: "shadow-md shadow-gray-500/5 dark:shadow-black/20",
      hover_shadow: "hover:shadow-lg hover:shadow-gray-500/10 dark:hover:shadow-black/30"
    },
    glass: {
      base: "bg-highlight",
      border: "border border-white/20 dark:border-white/10",
      shadow: "shadow-xl shadow-violet-500/5 dark:shadow-violet-400/10",
      hover_shadow: "hover:shadow-2xl hover:shadow-violet-500/10 dark:hover:shadow-violet-400/20"
    }
  }

  DEFAULT = {
    padding: :md,
    classes: "",
    variant: :default,
    glow: false
  }.freeze

  def initialize(options = {})
    options_merged = DEFAULT.merge(options)
    @padding = options_merged[:padding]
    @classes = options_merged[:classes]
    @variant = options_merged[:variant]
    @glow = options_merged[:glow]
  end

  def html_classes
    variant_config = VARIANT_STYLES[@variant]
    glow_effect = @glow ? "hover:shadow-[0_0_30px_rgba(139,69,244,0.15)] dark:hover:shadow-[0_0_40px_rgba(167,139,250,0.2)] focus-within:shadow-[0_0_30px_rgba(139,69,244,0.15)] dark:focus-within:shadow-[0_0_40px_rgba(167,139,250,0.2)]" : ""
    [
      "rounded-2xl transition-all duration-300 ease-out",
      "hover:-translate-y-1 hover:brightness-[1.02] dark:hover:brightness-102",
      "focus-within:-translate-y-1 focus-within:brightness-[1.02] dark:focus-within:brightness-110",
      "focus-within:ring-1 focus-within:ring-violet-500/30 focus-within:ring-offset-0.5 focus-within:ring-offset-transparent",
      variant_config[:base],
      variant_config[:border],
      variant_config[:shadow],
      variant_config[:hover_shadow],
      glow_effect,
      PADDING[@padding],
      "animate-slide-up",
      @classes
    ].reject(&:empty?).join(" ")
  end
end
