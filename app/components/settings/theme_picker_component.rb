class Settings::ThemePickerComponent < ApplicationViewComponent
  Theme = Data.define(:id, :name)
  Section = Data.define(:key, :themes, :title_colors, :desc_colors, :h2_class)

  option :current_theme, default: -> { "hyper" }

  THEMES_TECH_EDGE = [
    Theme.new(id: "hyper", name: "Hyper"),
    Theme.new(id: "aurora", name: "Aurora"),
    Theme.new(id: "eclipse", name: "Eclipse"),
    Theme.new(id: "galaxy", name: "Galaxy"),
    Theme.new(id: "synth", name: "Synth"),
    Theme.new(id: "thunder", name: "Thunder"),
    Theme.new(id: "matrix", name: "Matrix"),
    Theme.new(id: "cyber", name: "Cyber")
  ]

  THEMES_SERENE = [
    Theme.new(id: "botanic", name: "Botanic"),
    Theme.new(id: "reef", name: "Reef"),
    Theme.new(id: "oceanic", name: "Oceanic"),
    Theme.new(id: "forest", name: "Forest"),
    Theme.new(id: "dune", name: "Dune"),
    Theme.new(id: "mauve", name: "Mauve"),
    Theme.new(id: "glacier", name: "Glacier"),
    Theme.new(id: "lavender", name: "Lavender")
  ]

  THEMES_COSMIC = [
    Theme.new(id: "nebula", name: "Nebula"),
    Theme.new(id: "starlight", name: "Starlight"),
    Theme.new(id: "void", name: "Void"),
    Theme.new(id: "pulsar", name: "Pulsar"),
    Theme.new(id: "vapor", name: "Vapor"),
    Theme.new(id: "prism", name: "Prism"),
    Theme.new(id: "comet", name: "Comet"),
    Theme.new(id: "royal", name: "Royal")
  ]

  THEMES_VIVID = [
    Theme.new(id: "sunset", name: "Sunset"),
    Theme.new(id: "berry", name: "Berry"),
    Theme.new(id: "flamingo", name: "Flamingo"),
    Theme.new(id: "solar", name: "Solar"),
    Theme.new(id: "coral", name: "Coral"),
    Theme.new(id: "neon", name: "Neon"),
    Theme.new(id: "phoenix", name: "Phoenix"),
    Theme.new(id: "bloom", name: "Bloom")
  ]

  THEMES_NIGHT_OWL = [
    Theme.new(id: "amber", name: "Amber"),
    Theme.new(id: "candle", name: "Candle"),
    Theme.new(id: "ember", name: "Ember"),
    Theme.new(id: "hearth", name: "Hearth"),
    Theme.new(id: "vintage", name: "Vintage"),
    Theme.new(id: "sepia", name: "Sepia"),
    Theme.new(id: "autumn", name: "Autumn"),
    Theme.new(id: "twilight", name: "Twilight")
  ]

  SECTIONS = [
    Section.new(
      key: "tech_edge", themes: THEMES_TECH_EDGE,
      title_colors: %w[text-purple-500 text-cyan-500],
      desc_colors: %w[text-pink-500 text-slate-400\ dark:text-slate-300 text-blue-500],
      h2_class: nil
    ),
    Section.new(
      key: "serene", themes: THEMES_SERENE,
      title_colors: %w[text-emerald-500],
      desc_colors: %w[text-cyan-500 text-slate-400\ dark:text-slate-300 text-yellow-500],
      h2_class: "text-white"
    ),
    Section.new(
      key: "cosmic", themes: THEMES_COSMIC,
      title_colors: %w[text-sky-500],
      desc_colors: %w[text-fuchsia-500 text-slate-400\ dark:text-slate-300 text-orange-500],
      h2_class: nil
    ),
    Section.new(
      key: "vivid", themes: THEMES_VIVID,
      title_colors: %w[text-red-500],
      desc_colors: %w[text-lime-500 text-slate-400\ dark:text-slate-300 text-pink-500],
      h2_class: nil
    ),
    Section.new(
      key: "night_owl", themes: THEMES_NIGHT_OWL,
      title_colors: %w[text-orange-500 text-amber-500],
      desc_colors: %w[text-yellow-500 text-slate-400\ dark:text-slate-300 text-rose-500],
      h2_class: nil
    )
  ].freeze

  def section_title_words(section)
    I18n.t("settings.theme.#{section.key}.title").split(" ")
  end

  def section_desc_words(section)
    I18n.t("settings.theme.#{section.key}.description").split(" ")
  end

  def color_for(colors, index)
    colors[[index, colors.length - 1].min]
  end
end
