# frozen_string_literal: true

module AvatarAi
  class PromptAssembler
    GUIDED = 0
    FREEFORM = 1

    def assemble(avatar)
      case [avatar.read_attribute(:method), avatar.dna_version]
      when [GUIDED, 1]
        assemble_guided_v1(avatar.dna)
      when [FREEFORM, 1]
        assemble_freeform_v1(avatar.dna)
      else
        raise ArgumentError, "Unknown method/dna_version combination: #{avatar.read_attribute(:method)}/#{avatar.dna_version}"
      end
    end

    private

    def assemble_guided_v1(dna)
      parts = []

      parts << style_description(dna["style"]) if dna["style"]
      parts << archetype_description(dna["archetype"]) if dna["archetype"]
      parts << "digital avatar portrait"
      parts << mood_description(dna["mood"]) if dna["mood"]
      parts << color_description(dna, dna["color_mood"]) if dna["color_mood"]
      parts << elements_description(dna["elements"]) if dna["elements"]&.any?
      parts << background_description(dna["background"]) if dna["background"]
      parts << "high quality, detailed, centered composition"

      parts.compact.join(", ")
    end

    def assemble_freeform_v1(dna)
      parts = []

      parts << dna["spark_text"] if dna["spark_text"]
      parts << "digital avatar portrait"
      parts << "art style: #{dna["style_choice"]}" if dna["style_choice"]
      parts << concept_from_choice(dna["concept_choice"], dna["concepts"]) if dna["concept_choice"]
      parts << color_preference_description(dna["color_preference"]) if dna["color_preference"]
      parts << background_description(dna["background"]) if dna["background"]
      parts << "high quality, detailed, centered composition"

      parts.compact.join(", ")
    end

    def style_description(style)
      {
        "pixel_art" => "pixel art style, 8-bit retro aesthetic",
        "watercolor" => "watercolor painting style, soft brushstrokes",
        "geometric" => "geometric abstract art, sharp angles and shapes",
        "anime" => "anime manga illustration style",
        "3d_clay" => "3D render, clay toy style, smooth surfaces",
        "line_art" => "clean line art, minimalist illustration",
        "collage" => "mixed media collage art, layered textures",
        "surrealist" => "surrealist dreamlike imagery"
      }[style]
    end

    def archetype_description(archetype)
      {
        "explorer" => "adventurous explorer energy, curious and bold",
        "builder" => "creative builder energy, constructive and determined",
        "guardian" => "protective guardian energy, strong and dependable",
        "trickster" => "playful trickster energy, mischievous and clever",
        "sage" => "wise sage energy, thoughtful and mysterious",
        "spark" => "vibrant spark energy, energetic and inspiring"
      }[archetype]
    end

    def mood_description(mood)
      {
        "calm" => "calm serene atmosphere",
        "bold" => "bold powerful atmosphere",
        "mysterious" => "mysterious dark atmosphere",
        "whimsical" => "whimsical fun atmosphere",
        "futuristic" => "futuristic tech atmosphere",
        "nostalgic" => "nostalgic vintage atmosphere"
      }[mood]
    end

    def color_description(dna, color_mood)
      if color_mood == "custom" && dna["custom_colors"]&.any?
        "color palette: #{dna["custom_colors"].join(", ")}"
      else
        {
          "warm_sunset" => "warm sunset color palette: oranges, reds, golds",
          "deep_ocean" => "deep ocean color palette: blues, teals, dark purples",
          "neon_night" => "neon night color palette: electric blues, magentas, greens",
          "earth_moss" => "earth and moss color palette: greens, browns, warm neutrals",
          "monochrome" => "monochrome black and white palette",
          "candy_pop" => "candy pop color palette: pastel pinks, blues, yellows"
        }[color_mood]
      end
    end

    def elements_description(elements)
      return nil unless elements&.any?
      "featuring #{elements.join(", ")}"
    end

    def background_description(background)
      {
        "transparent" => "transparent background",
        "gradient" => "gradient background",
        "scene" => "detailed scene background",
        "pattern" => "patterned background"
      }[background]
    end

    def color_preference_description(preference)
      {
        "warm" => "warm color tones",
        "cool" => "cool color tones",
        "vibrant" => "vibrant saturated colors",
        "muted" => "muted desaturated palette",
        "auto" => nil
      }[preference]
    end

    def concept_from_choice(choice_index, concepts)
      return nil unless choice_index
      concepts&.at(choice_index.to_i)
    end
  end
end
