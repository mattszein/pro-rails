class Settings::ThemePickerComponent < ViewComponent::Base
  Theme = Data.define(:id, :name)
  attr_reader :current_theme

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

  def initialize(current_theme:)
    @current_theme = current_theme || "hyper"
  end
end
