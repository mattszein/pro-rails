
module AvatarAi
  module Prompts
    module Vocabulary
      STYLES = {
        "pixel_art" => "pixel art style, 8-bit retro aesthetic",
        "watercolor" => "watercolor painting style, soft brushstrokes",
        "geometric" => "geometric abstract art, sharp angles and shapes",
        "anime" => "anime manga illustration style",
        "3d_clay" => "3D render, clay toy style, smooth surfaces",
        "line_art" => "clean line art, minimalist illustration",
        "collage" => "mixed media collage art, layered textures",
        "surrealist" => "surrealist dreamlike imagery"
      }.freeze

      ARCHETYPES = {
        "explorer" => "adventurous explorer energy, curious and bold",
        "builder" => "creative builder energy, constructive and determined",
        "guardian" => "protective guardian energy, strong and dependable",
        "trickster" => "playful trickster energy, mischievous and clever",
        "sage" => "wise sage energy, thoughtful and mysterious",
        "spark" => "vibrant spark energy, energetic and inspiring"
      }.freeze

      MOODS = {
        "calm" => "calm serene atmosphere",
        "bold" => "bold powerful atmosphere",
        "mysterious" => "mysterious dark atmosphere",
        "whimsical" => "whimsical fun atmosphere",
        "futuristic" => "futuristic tech atmosphere",
        "nostalgic" => "nostalgic vintage atmosphere"
      }.freeze

      COLOR_MOODS = {
        "warm_sunset" => "warm sunset color palette: oranges, reds, golds",
        "deep_ocean" => "deep ocean color palette: blues, teals, dark purples",
        "neon_night" => "neon night color palette: electric blues, magentas, greens",
        "earth_moss" => "earth and moss color palette: greens, browns, warm neutrals",
        "monochrome" => "monochrome black and white palette",
        "candy_pop" => "candy pop color palette: pastel pinks, blues, yellows"
      }.freeze

      BACKGROUNDS = {
        "transparent" => "transparent background",
        "gradient" => "gradient background",
        "scene" => "detailed scene background",
        "pattern" => "patterned background"
      }.freeze

      COLOR_PREFERENCES = {
        "warm" => "warm color tones",
        "cool" => "cool color tones",
        "vibrant" => "vibrant saturated colors",
        "muted" => "muted desaturated palette",
        "auto" => nil
      }.freeze

      module_function

      def style_description(style) = STYLES[style]

      def archetype_description(archetype) = ARCHETYPES[archetype]

      def mood_description(mood) = MOODS[mood]

      def color_description(color_mood, custom_colors: nil)
        if color_mood == "custom" && custom_colors&.any?
          "color palette: #{custom_colors.join(", ")}"
        else
          COLOR_MOODS[color_mood]
        end
      end

      def elements_description(elements)
        return nil unless elements&.any?
        "featuring #{elements.join(", ")}"
      end

      def background_description(background) = BACKGROUNDS[background]

      def color_preference_description(preference) = COLOR_PREFERENCES[preference]
    end
  end
end
