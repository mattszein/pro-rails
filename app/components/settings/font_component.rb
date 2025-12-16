class Settings::FontComponent < ApplicationViewComponent
  option :current_font
  Font = Data.define(:id, :name, :category, :description)

  FONTS = [
    Font.new(id: "inter", name: "Inter", category: "modern", description: "Clean & versatile"),
    Font.new(id: "plus-jakarta", name: "Plus Jakarta", category: "serene", description: "Soft & readable"),
    Font.new(id: "space-grotesk", name: "Space Grotesk", category: "cosmic", description: "Futuristic & quirky"),
    Font.new(id: "outfit", name: "Outfit", category: "vivid", description: "Bold & energetic"),
    Font.new(id: "bricolage", name: "Bricolage Grotesque", category: "warm", description: "Cozy & characterful"),
    Font.new(id: "google-sans-code", name: "Google Code", category: "code", description: "Developer-friendly"),
    Font.new(id: "orbitron", name: "Orbitron", category: "cyberpunk", description: "Sci-fi & neon"),
    Font.new(id: "manrope", name: "Manrope", category: "minimal", description: "Swiss & professional")
  ]
end
