class Settings::FontComponent < ApplicationViewComponent
  option :current_font
  Font = Data.define(:id, :name, :category, :description_key)

  FONTS = [
    Font.new(id: "inter", name: "Inter", category: "modern", description_key: "inter"),
    Font.new(id: "plus-jakarta", name: "Plus Jakarta", category: "serene", description_key: "plus_jakarta"),
    Font.new(id: "space-grotesk", name: "Space Grotesk", category: "cosmic", description_key: "space_grotesk"),
    Font.new(id: "outfit", name: "Outfit", category: "vivid", description_key: "outfit"),
    Font.new(id: "bricolage", name: "Bricolage Grotesque", category: "warm", description_key: "bricolage"),
    Font.new(id: "google-sans-code", name: "Google Code", category: "code", description_key: "google_code"),
    Font.new(id: "orbitron", name: "Orbitron", category: "cyberpunk", description_key: "orbitron"),
    Font.new(id: "manrope", name: "Manrope", category: "minimal", description_key: "manrope")
  ]
end
