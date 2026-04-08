class Settings::FontComponent < ApplicationViewComponent
  option :current_font
  Font = Data.define(:id, :name, :category, :description_key)

  FONTS = [
    Font.new(id: "inter", name: "Inter", category: "modern", description_key: "inter"),
    Font.new(id: "lora", name: "Lora", category: "editorial", description_key: "lora"),
    Font.new(id: "space-grotesk", name: "Space Grotesk", category: "cosmic", description_key: "space_grotesk"),
    Font.new(id: "outfit", name: "Outfit", category: "vivid", description_key: "outfit"),
    Font.new(id: "jost", name: "Jost", category: "elegant", description_key: "jost"),
    Font.new(id: "google-sans-code", name: "Google Code", category: "code", description_key: "google_code"),
    Font.new(id: "orbitron", name: "Orbitron", category: "cyberpunk", description_key: "orbitron"),
    Font.new(id: "chakra-petch", name: "Chakra Petch", category: "anime", description_key: "chakra_petch")
  ]
end
